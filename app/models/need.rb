require "active_model"

class Need
  extend ActiveModel::Naming
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
    PAGINATION_PARAMS = [:pages, :total, :page_size, :current_page, :start_index]
    attr_reader *PAGINATION_PARAMS

    def initialize(needs, pagination_info)
      super(needs)

      @pages = pagination_info["pages"]
      @total = pagination_info["total"]
      @page_size = pagination_info["page_size"]
      @current_page = pagination_info["current_page"]
      @start_index = pagination_info["start_index"]
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

  FIELDS_WITH_ARRAY_VALUES = %w(organisations revisions status)

  alias_method :need_id, :id

  validates_presence_of %w(role goal benefit)
  validates :impact, inclusion: { in: IMPACT }, allow_blank: true
  validates_each :justifications do |record, attr, value|
    record.errors.add(attr, "must contain a known value") unless value.nil? || value.all? { |v| JUSTIFICATIONS.include? v }
  end
  NUMERIC_FIELDS.each do |field|
    validates_numericality_of field, only_integer: true, allow_blank: true, greater_than_or_equal_to: 0
  end

  # Retrieve a list of needs from the Need API
  #
  # The parameters are the same as passed through to the Need API: as of
  # 2014-03-12, they are `organisation_id`, `page` and `q`.
  def self.list(options = {})
    need_response = Maslow.need_api.needs(options)

    need_objects = need_response["results"].map { |need_hash| self.new(need_hash, true) }
    PaginatedList.new(need_objects, need_response)
  end

  # Retrieve a list of needs matching an array of ids
  #
  # Note that this returns the entire set of matching ids and not a
  # PaginatedList
  def self.by_ids(*ids)
    response = Maslow.need_api.needs_by_id(ids.flatten)

    response.with_subsequent_pages.map { |need| self.new(need, true) }
  end

  # Retrieve a need from the Need API, or raise NotFound if it doesn't exist.
  #
  # This works in roughly the same way as an ActiveRecord-style `find` method,
  # just with a different exception type.
  def self.find(need_id)
    need_response = Maslow.need_api.need(need_id)
    self.new(need_response.to_hash, true)
  rescue GdsApi::HTTPNotFound
    raise NotFound, need_id
  end

  def initialize(attrs)
    strip_newline_from_textareas(attrs)

    attrs.each do |field, value|
      assign_attribute_value(field, value)
    end

    @met_when ||= []
    @justifications ||= []
    @organisation_ids ||= []
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

    attrs.keys.each do |f|
      send("#{f}=", attrs[f])
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
    res = (WRITABLE_FIELDS).each_with_object({}) do |field, hash|
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
    atts = as_json.merge("author" => author_atts(author))

    if persisted?
      Maslow.need_api.update_need(@id, atts)
    else
      response_hash = Maslow.need_api.create_need(atts).to_hash

      update(response_hash)
    end
    true
  rescue GdsApi::HTTPErrorResponse => err
    false
  end

  def has_invalid_status?
    status.description == "not valid"
  end

private

  def assign_attribute_value(field, value)
    if FIELDS_WITH_ARRAY_VALUES.include?(field)
      set_organisations(value) if field == "organisations"
      set_status(value) if field == "status"
      set_revisions(value) if field == "revisions"
    else
      send("#{field}=", value)
    end
  end

  def set_organisations(organisations)
    organisations = [] if organisations.blank?
    instance_variable_set("@organisations", organisations)
  end

  def set_status(status)
    status = nil if status.blank?
    instance_variable_set("@status", NeedStatus.new(status))
  end

  def set_revisions(revisions)
    revisions = [] if revisions.blank?
    revisions.each_with_index do |revision, i|
      revision["changes"] = revisions[i]["changes"]
    end
    instance_variable_set("@revisions", revisions)
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
