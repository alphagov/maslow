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

  class BasePathAlreadyInUse < StandardError
    attr_reader :content_id

    def initialize(content_id)
      super("Publishing API rejected update as the base path is already in use")
      @content_id = content_id
    end
  end

  # Allow us to convert the API response to a list of Need objects, but still
  # retain the pagination information
  class PaginatedList < Array
    PAGINATION_PARAMS = %i[pages total per_page current_page].freeze
    attr_reader(*PAGINATION_PARAMS)

    def initialize(needs, pages:, total:, current_page:, per_page:)
      super(needs)

      @pages = pages
      @total = total
      @per_page = per_page
      @current_page = current_page
    end

    def inspect
      pagination_params = PAGINATION_PARAMS.index_with { |param_name| send(param_name) }
      "#<#{self.class} #{super}, #{pagination_params}>"
    end

    def to_options
      map do |need|
        [need.benefit, need.content_id]
      end
    end
  end

  JUSTIFICATIONS = [
    "It's something only government does",
    "The government is legally obliged to provide it",
    "It's inherent to a person's or an organisation's rights and obligations",
    "It's something that people can do or it's something people need to know before they can do something that's regulated by/related to government",
    "There is clear demand for it from users",
    "It's something the government provides/does/pays for",
    "It's straightforward advice that helps people to comply with their statutory obligations",
  ].freeze
  IMPACT = [
    "No impact",
    "Noticed only by an expert audience",
    "Noticed by the average member of the public",
    "Has consequences for the majority of your users",
    "Has serious consequences for your users and/or their customers",
    "Endangers people",
  ].freeze

  NUMERIC_FIELDS = %w[yearly_user_contacts yearly_site_views yearly_need_views yearly_searches].freeze

  FIELDS_WITH_ARRAY_VALUES = %w[met_when justifications organisation_ids].freeze

  PUBLISHING_API_FIELDS = %w[
    base_path
    content_id
    description
    details
    first_published_at
    last_edited_at
    locale
    phase
    public_updated_at
    publication_state
    redirects
    routes
    schema_name
    state_history
    title
    unpublishing
    update_type
    updated_at
    user_facing_version
    version
  ].freeze

  ALLOWED_FIELDS = NUMERIC_FIELDS + FIELDS_WITH_ARRAY_VALUES + PUBLISHING_API_FIELDS + %w[need_id role goal benefit impact legislation other_evidence applies_to_all_organisations]

  attr_accessor :persisted, :met_when, :justifications, :organisation_ids, :content_id
  alias_method :persisted?, :persisted
  alias_method :id, :content_id

  validates :role, :goal, :benefit, presence: true
  validates :impact, inclusion: { in: IMPACT }, allow_blank: true
  validates_each :justifications do |record, attr, value|
    record.errors.add(attr, "must contain a known value") unless value.nil? || value.all? { |v| JUSTIFICATIONS.include? v }
  end
  NUMERIC_FIELDS.each do |field|
    validates field, numericality: { only_integer: true, allow_blank: true, greater_than_or_equal_to: 0 }
  end

  def initialize(attributes = {})
    ALLOWED_FIELDS.each { |field| singleton_class.class_eval { attr_accessor field.to_s } }

    default_values = {
      "content_id" => SecureRandom.uuid,
      "met_when" => [],
      "justifications" => [],
      "organisation_ids" => [],
      "update_type" => "major",
    }

    update(
      default_values.merge(attributes.to_h),
    )

    # This is set to true when data is loaded in from the Publishing
    # API, forms use this to decide what route to post to
    @persisted = false
  end

  # Retrieve a list of needs from the Publishing API
  def self.list(options = {})
    options = default_options.merge(options.to_h.symbolize_keys)
    if options.key? :organisation_id
      options[:link_organisations] = options.delete(:organisation_id)
    end
    response = GdsApi.publishing_api.get_content_items(
      options.except(:load_organisation_ids),
    )
    need_objects = needs_from_publishing_api_payloads(
      response["results"].to_a,
      load_organisation_ids: options.fetch(:load_organisation_ids, true),
    )
    PaginatedList.new(
      need_objects,
      pages: response["pages"],
      total: response["total"],
      current_page: response["current_page"],
      per_page: options[:per_page],
    )
  end

  # Retrieve a list of needs matching an array of ids
  #
  # Note that this returns the entire set of matching ids and not a
  # PaginatedList
  def self.by_content_ids(*content_ids)
    needs = content_ids.map do |content_id|
      Need.find(content_id)
    rescue NotFound
      nil
    end
    needs.compact
  end

  # Retrieve a need from the Publishing API, or raise NotFound if it doesn't exist.
  #
  # This works in roughly the same way as an ActiveRecord-style `find` method,
  # just with a different exception type.
  def self.find(content_id)
    response = GdsApi.publishing_api.get_content(content_id)
    need_from_publishing_api_payload(response.parsed_content)
  rescue GdsApi::HTTPNotFound
    raise NotFound, content_id
  end

  def revisions
    return @responses if @responses

    latest_revision = fetch_from_publishing_api(@content_id)
    version = latest_revision["user_facing_version"]
    @responses = [latest_revision]
    while version > 1
      version -= 1
      @responses << fetch_from_publishing_api(@content_id, version: version)
    end
    compute_changes(@responses)
  end

  def fetch_from_publishing_api(content_id, params = {})
    response = GdsApi.publishing_api.get_content(content_id, params).parsed_content
    self.class.move_details_to_top_level(response)
  end

  def load_organisation_ids
    parsed_content =
      GdsApi.publishing_api.get_links(@content_id).parsed_content
    @organisation_ids = parsed_content["links"]["organisations"] || []
  end

  def organisations
    # There is currently no way to get organisations data from the
    # Publishing API when getting the content, so to get the
    # Organisation instances for a Need, filter the list of all
    # organisations (which should be cached).
    @organisations ||= Organisation.all.select do |organisation|
      @organisation_ids.include? organisation.content_id
    end
  end

  def add_more_criteria
    @met_when << ""
  end

  def remove_criteria(index)
    @met_when.delete_at(index)
  end

  def unpublished?
    publication_state == "unpublished"
  end

  def published?
    publication_state == "published"
  end

  def draft?
    publication_state == "draft"
  end

  def update(attrs)
    strip_newline_from_textareas(attrs)

    attrs.each do |field, value|
      if FIELDS_WITH_ARRAY_VALUES.include?(field)
        set_attribute(field, value)
      elsif NUMERIC_FIELDS.include?(field)
        send(
          "#{field}=",
          value.blank? ? nil : value.to_i,
        )
      else
        send("#{field}=", value)
      end
    end

    @met_when ||= []
    @justifications ||= []
    @organisation_ids ||= [] # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def content_items_meeting_this_need
    @content_items_meeting_this_need ||=
      GdsApi.publishing_api.get_linked_items(
        content_id,
        link_type: "meets_user_needs",
        fields: %w[title base_path document_type],
      )
  rescue GdsApi::HTTPErrorResponse => e
    logger.error("GdsApi::HTTPErrorResponse in Need.content_items_meeting_this_need")
    logger.error(e)
    GovukError.notify(e)
    false
  end

  def publish
    if unpublished?
      # Save to ensure that a draft exists to Publish
      save
    end

    GdsApi.publishing_api.publish(content_id, "major")
  rescue GdsApi::HTTPErrorResponse => e
    logger.error("GdsApi::HTTPErrorResponse in Need.publish")
    logger.error(e)
    GovukError.notify(e)
    false
  end

  def discard
    GdsApi.publishing_api.discard_draft(content_id)
  rescue GdsApi::HTTPErrorResponse => e
    logger.error("GdsApi::HTTPErrorResponse in Need.discard")
    logger.error(e)
    GovukError.notify(e)
    false
  end

  def unpublish(explanation)
    GdsApi.publishing_api.unpublish(
      content_id,
      type: "withdrawal",
      explanation: explanation,
    )
  rescue GdsApi::HTTPErrorResponse => e
    logger.error("GdsApi::HTTPErrorResponse in Need.unpublish")
    logger.error(e)
    GovukError.notify(e)
    false
  end

  def save
    strip_newline_from_textareas(publishing_api_payload)

    GdsApi.publishing_api.put_content(
      content_id,
      publishing_api_payload,
    )

    GdsApi.publishing_api.patch_links(
      content_id,
      links: {
        "organisations": organisation_ids,
      },
    )
  rescue GdsApi::HTTPErrorResponse => e
    if e.error_details.is_a?(Hash)
      message = e.error_details.dig "error", "message"
      if message
        conflicting_content_id = /content_id=([^\s]+)/.match(message)[1]

        if conflicting_content_id
          raise BasePathAlreadyInUse, conflicting_content_id
        end
      end
    end

    logger.error("GdsApi::HTTPErrorResponse in Need.save")
    logger.error(e)
    GovukError.notify(e)
    false
  end

  def to_key
    if persisted?
      [content_id]
    end
  end

  def status
    case publication_state
    when "published"
      "Valid"
    when "draft"
      "Proposed"
    when "unpublished"
      "Withdrawn"
    else
      raise "publication_state: #{publication_state} not recognised"
    end
  end

  def self.needs_from_publishing_api_payloads(responses, load_organisation_ids: true)
    responses.map do |x|
      need_from_publishing_api_payload(
        x,
        load_organisation_ids: load_organisation_ids,
      )
    end
  end

  def self.need_from_publishing_api_payload(attributes, load_organisation_ids: true)
    attributes = move_details_to_top_level(attributes)
    whitelisted_attributes = attributes.slice(*ALLOWED_FIELDS)

    need = Need.new(whitelisted_attributes)
    need.load_organisation_ids if load_organisation_ids
    need.persisted = true

    need
  end

  def self.move_details_to_top_level(attributes)
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

    attributes_without_nested_details.merge(attributes["details"] || {})
  end

  def self.default_options
    {
      document_type: "need",
      per_page: 50,
      fields: %w[content_id details publication_state],
      locale: "en",
      order: "-updated_at",
    }
  end

private

  def publishing_api_payload
    details_fields = (ALLOWED_FIELDS - PUBLISHING_API_FIELDS) - %w[organisation_ids]
    details = details_fields.each_with_object({}) do |field, hash|
      value = send(field)
      next if value.blank?

      hash[field] = value.as_json
    end

    title_suffix = need_id ? " (#{need_id})" : ""
    update(base_path: "/needs/#{goal.parameterize}") unless base_path

    {
      schema_name: "need",
      publishing_app: "maslow",
      rendering_app: "info-frontend",
      locale: "en",
      base_path: base_path,
      routes: [
        {
          path: base_path,
          type: "exact",
        },
      ],
      document_type: "need",
      title: "As a #{@role}, I need to #{@goal}, so that #{@benefit}#{title_suffix}",
      details: details,
      update_type: update_type,
    }
  end

  def set_attribute(field, value)
    value = [] if value.blank?
    instance_variable_set("@#{field}", value)
  end

  def author_atts(author)
    {
      "name" => author.name,
      "email" => author.email,
      "uid" => author.uid,
    }
  end

  def strip_newline_from_textareas(attrs)
    # Rails prepends a newline character into the textarea fields in the form.
    # Strip these so that we don't send them to the Publishing API.
    %i[legislation other_evidence].each do |field|
      attrs[field].sub!(/\A\n/, "") if attrs[field].present?
    end
  end

  def compute_changes(responses)
    responses.each_with_index do |current_version, index|
      index_of_previous_version = index + 1
      previous_version = responses[index_of_previous_version] || {}
      current_version["changes"] = changes(previous_version, current_version)
    end
  end

  def changes(previous, current)
    versions = [previous, current]

    keys = changed_keys(current, previous) - %w[user_facing_version]

    keys.inject({}) do |changes, key|
      changes.merge(key => versions.map { |version| version[key] })
    end
  end

  def changed_keys(current, previous)
    (current.keys | previous.keys).reject do |key|
      current[key] == previous[key]
    end
  end
end
