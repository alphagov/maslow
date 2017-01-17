require "active_model"

class Need
  extend ActiveModel::Naming
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Serialization

  class NotFound < StandardError
    attr_reader :need_id

    def initialize(need_id)
      super("Need with ID #{need_id} not found")
      @need_id = need_id
    end
  end

  # Allow us to convert the API response to a list of Need objects, but still
  # retain the pagination information
  class PaginatedList < Array
    PAGINATION_PARAMS = [:pages, :total, :per_page, :page]
    attr_reader *PAGINATION_PARAMS

    def initialize(needs, pagination_info)
      super(needs)

      @pages = pagination_info["pages"]
      @total = pagination_info["total"]
      @per_page = pagination_info["per_page"]
      @page = pagination_info["page"]
    end

    def inspect
      pagination_params = Hash[
        PAGINATION_PARAMS.map { |param_name| [param_name, send(param_name)] }
      ]
      "#<#{self.class} #{super}, #{pagination_params}>"
    end
  end

  JUSTIFICATIONS = [
    "It's something only government does",
    "The government is legally obliged to provide it",
    "It's inherent to a person's or an organisation's rights and obligations",
    "It's something that people can do or it's something people need to know before they can do something that's regulated by/related to government",
    "There is clear demand for it from users",
    "It's something the government provides/does/pays for",
    "It's straightforward advice that helps people to comply with their statutory obligations"
  ]
  IMPACT = [
    "No impact",
    "Noticed only by an expert audience",
    "Noticed by the average member of the public",
    "Has consequences for the majority of your users",
    "Has serious consequences for your users and/or their customers",
    "Endangers people"
  ]

  NUMERIC_FIELDS = %w(yearly_user_contacts yearly_site_views yearly_need_views yearly_searches)

  FIELDS_WITH_ARRAY_VALUES = %w(status met_when justifications organisation_ids)

  PUBLISHING_API_FIELDS = %w(title base_path schema_name locale phase redirects update_type public_updated_at first_published_at last_edited_at publication_state state_history routes description)

  ALLOWED_FIELDS = NUMERIC_FIELDS + FIELDS_WITH_ARRAY_VALUES + PUBLISHING_API_FIELDS + %w(content_id need_id role goal benefit impact legislation other_evidence duplicate_of applies_to_all_organisations)

  attr_accessor :met_when, :justifications, :organisation_ids

  validates_presence_of %w(role goal benefit)
  validates :impact, inclusion: { in: IMPACT }, allow_blank: true
  validates_each :justifications do |record, attr, value|
    record.errors.add(attr, "must contain a known value") unless value.nil? || value.all? { |v| JUSTIFICATIONS.include? v }
  end
  NUMERIC_FIELDS.each do |field|
    validates_numericality_of field, only_integer: true, allow_blank: true, greater_than_or_equal_to: 0
  end

  def initialize(attributes={})
    ALLOWED_FIELDS.each {|field| singleton_class.class_eval { attr_accessor "#{field}" } }

    strip_newline_from_textareas(attributes)

    default_values = {
      "content_id" => SecureRandom.uuid,
      "met_when" => [],
      "justifications" => [],
      "organisation_ids" => [],
    }

    update(
      default_values.merge(attributes)
    )
  end

  # Retrieve a list of needs from the Need API
  #
  # The parameters are the same as passed through to the Need API: as of
  # 2014-03-12, they are `organisation_id`, `page` and `q`.
  def self.list(options = {})
    options = default_options.merge(options)
    response = Maslow.publishing_api_v2.get_content_items(options)
    need_objects = needs_from_publishing_api_payloads(*response["results"].to_a)
    PaginatedList.new(need_objects, response)
  end

  # Retrieve a list of needs matching an array of ids
  #
  # Note that this returns the entire set of matching ids and not a
  # PaginatedList
  def self.by_content_ids(*content_ids)
    content_ids.map do |content_id|
      response = Maslow.publishing_api_v2.get_content(content_id)
      need_from_publishing_api_payload(response.parsed_content)
    end
  end

  # Retrieve a need from the Publishing API, or raise NotFound if it doesn't exist.
  #
  # This works in roughly the same way as an ActiveRecord-style `find` method,
  # just with a different exception type.
  def self.find(content_id)
    response = Maslow.publishing_api_v2.get_content(content_id)
    need_from_publishing_api_payload(response.parsed_content)
  rescue GdsApi::HTTPNotFound
    raise NotFound, content_id
  end

  def organisations
    org_response = Maslow.publishing_api_v2.get_expanded_links(@content_id)
    response = org_response["expanded_links"]["organisations"] || []
    @organisations ||= response.map do |org|
      Organisation.new(
        title: org.deep_symbolize_keys[:title],
        content_id: org.deep_symbolize_keys[:content_id],
        details: {}
      )
    end
    @organisations
  end

  def add_more_criteria
    @met_when << ""
  end

  def remove_criteria(index)
    @met_when.delete_at(index)
  end

  def duplicate?
    duplicate_of.present?
  end

  def update(attrs)
    strip_newline_from_textareas(attrs)

    attrs.each do |field, value|
      if FIELDS_WITH_ARRAY_VALUES.include?(field)
        case field
        when "organisations", "met_when", "justifications", "organisation_ids"
          set_attribute(field, value)
        when "status"
          set_status(value)
        else
          raise "attribute unknown: #{field}"
        end
      else
        send("#{field}=", value)
      end
    end

    @met_when ||= []
    @justifications ||= []
    @organisation_ids ||= []
  end

  def artefacts
    @artefacts ||= Maslow.content_api.for_need(@id)
  rescue GdsApi::BaseError
    []
  end

  def as_json(options = {})
    # Build up the hash manually, as ActiveModel::Serialization's default
    # behaviour serialises all attributes, including @errors and
    # @validation_context.
    remove_blank_met_when_criteria
    res = (ALLOWED_FIELDS).each_with_object({}) do |field, hash|
      value = send(field)
      if value.present?
        # if this is a numeric field, force the value we send to the API to be an
        # integer
        value = Integer(value) if NUMERIC_FIELDS.include?(field)
      end

      # catch empty text fields and send them as null values instead for consistency
      # with updates on other fields
      value = nil if value == ""

      hash[field] = value.as_json
    end
  end

  def save
    raise("The save_as method must be used when persisting a need, providing details about the author.")
  end

  def close_as(author)
    duplicate_atts = {
      "duplicate_of" => @duplicate_of,
      "author" => author_atts(author)
    }
    Maslow.need_api.close(@id, duplicate_atts)
    true
  rescue GdsApi::HTTPErrorResponse => err
    false
  end

  def reopen_as(author)
    Maslow.need_api.reopen(@id, "author" => author_atts(author))
    true
  rescue GdsApi::HTTPErrorResponse => err
    false
  end

  def save_as(author)
    attributes = as_json.merge("author" => author_atts(author))
    content_id = attributes["content_id"]
    attributes = attributes.except("content_id", "organisations", "status")

    response_hash = Maslow.publishing_api_v2.put_content(content_id, attributes)
    update(response_hash)

    true
  rescue GdsApi::HTTPErrorResponse => err
    false
  end

  def has_invalid_status?
    status.description == "not valid"
  end

private

  def self.needs_from_publishing_api_payloads(*responses)
    responses.map { |x| need_from_publishing_api_payload(x) }
  end

  def self.need_from_publishing_api_payload(attributes)
    # Transforms the attributes to not have a nested details hash, and
    # instead have all the values in the details hash as top level
    # fields for convenience.
    #
    # {
    #   "content_id": "...",
    #   "details": {
    #     "role": "foo",
    #     ...
    #   }
    # }
    #
    # Would be transformed to:
    #
    # {
    #   "content_id": "...",
    #   "role": "foo"
    # }

    attributes_without_nested_details = attributes.except("details")
    attributes_with_merged_details =
      attributes_without_nested_details.merge(attributes["details"] || {})

    need_status = Need.map_to_status(attributes["state"])

    Need.new(
      attributes_with_merged_details
        .except("publishing_app", "rendering_app", "need_ids", "state")
        .merge({ "status" => need_status })
    )
  end

  def set_attribute(field, value)
    value = [] if value.blank?
    instance_variable_set("@#{field}", value)
  end

  def set_status(status)
    status = nil if status.blank?
    instance_variable_set("@status", NeedStatus.new(description: status)) #expects description
  end

  def self.default_options
    {
      document_type: 'need',
      per_page: 50,
      publishing_app: 'need-api',
      fields: ['content_id', 'need_ids', 'details', 'publication_state'],
      locale: 'en',
      order: '-public_updated_at'
    }
  end

  def self.map_to_status(state)
    case state
    when "published"
      "Valid"
    when "draft"
      "Proposed"
    when "unpublished"
      "Duplicate"
    else
      "Status not recognised: #{state}"
    end
  end

  def author_atts(author)
    {
      "name" => author.name,
      "email" => author.email,
      "uid" => author.uid
    }
  end

  def remove_blank_met_when_criteria
    met_when.delete_if(&:empty?) if met_when
  end

  def strip_newline_from_textareas(attrs)
    # Rails prepends a newline character into the textarea fields in the form.
    # Strip these so that we don't send them to the Need API.
    %w(legislation other_evidence).each do |field|
      attrs[field].sub!(/\A\n/, "") if attrs[field].present?
    end
  end
end
