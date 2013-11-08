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
  NUMERIC_FIELDS = ["monthly_user_contacts", "monthly_site_views", "monthly_need_views", "monthly_searches"]
  FIELDS = ["role", "goal", "benefit", "organisation_ids", "impact", "justifications", "met_when",
    "currently_met", "other_evidence", "legislation"] + NUMERIC_FIELDS
  attr_accessor *FIELDS
  attr_reader :need_id, :revisions

  validates_presence_of ["role", "goal", "benefit"]
  validates :impact, inclusion: { in: IMPACT }, allow_blank: true
  validates_each :justifications do |record, attr, value|
    record.errors.add(attr, "must contain a known value") unless (value.nil? || value.all? { |v| JUSTIFICATIONS.include? v })
  end
  NUMERIC_FIELDS.each do |field|
    validates_numericality_of field, :only_integer => true, :allow_blank => true, :greater_than_or_equal_to => 0
  end

  # Retrieve a need from the Need API, or raise NotFound if it doesn't exist.
  #
  # This works in roughly the same way as an ActiveRecord-style `find` method,
  # just with a different exception type.
  def self.find(need_id)
    need_response = Maslow.need_api.need(need_id)
    if need_response
      # Discard fields from the API we don't understand. Coupling the fields
      # this app understands to the fields it expects from clients is fine, but
      # we don't want to couple that with the fields we can use in the API.
      self.new(need_response.to_hash.slice(*FIELDS + ["id", "revisions"]), true)
    else
      raise NotFound, need_id
    end
  end

  def initialize(attrs, existing = false)
    if existing
      @need_id = attrs.delete("id")
      @revisions = prepare_revisions(attrs.delete("revisions"))
    end
    @existing = existing

    update(attrs)
  end

  def add_more_criteria
    @met_when << ""
  end

  def update(attrs)
    @met_when ||= []
    strip_newline_from_textareas(attrs)

    unless (attrs.keys - FIELDS).empty?
      raise(ArgumentError, "Unrecognised attributes present in: #{attrs.keys}")
    end
    attrs.keys.each do |f|
      send("#{f}=", attrs[f])
    end
  end

  def as_json(options = {})
    # Build up the hash manually, as ActiveModel::Serialization's default
    # behaviour serialises all attributes, including @errors and
    # @validation_context.
    remove_blank_met_when_criteria
    res = (FIELDS + NUMERIC_FIELDS).each_with_object({}) do |field, hash|
      if value = send(field) and value.present?


        # if this is a numeric field, force the value we send to the API to be an
        # integer
        value = Integer(value) if NUMERIC_FIELDS.include?(field)
      end

      hash[field] = value
    end

    res["currently_met"] = (currently_met == true || currently_met == 'true') unless currently_met.nil?
    res
  end

  def save
    raise("The save_as method must be used when persisting a need, providing details about the author.")
  end

  def save_as(author)
    atts = as_json.merge("author" => {
      "name" => author.name,
      "email" => author.email,
      "uid" => author.uid
    })

    if persisted?
      Maslow.need_api.update_need(@need_id, atts)
    else
      Maslow.need_api.create_need(atts)
    end
  rescue GdsApi::HTTPErrorResponse => err
    false
  end

  def persisted?
    @existing
  end

private
  def id
    # This method is required, because otherwise:
    #
    #   `semantic_form_for` from Formtastic invokes
    #   `form_for` from Rails, which invokes
    #   `dom_id` from ActionController, which invokes
    #   `to_key` from ActiveModel, which falls over
    @need_id
  end

  def prepare_revisions(revisions)
    return [] unless revisions.present?

    structs = GdsApi::Response.build_ostruct_recursively(revisions)

    # Return changes as a hash, rather than an OpenStruct because
    # we would like changes to be returned as field-value pairs
    structs.each_with_index do |revision, i|
      revision.changes = revisions[i]["changes"]
    end
  end

  def remove_blank_met_when_criteria
    if met_when
      met_when.delete_if(&:empty?)
    end
  end

  def strip_newline_from_textareas(attrs)
    # Rails prepends a newline character into the textarea fields in the form.
    # Strip these so that we don't send them to the Need API.
    ["legislation", "other_evidence"].each do |field|
      attrs[field].sub!(/\A\n/, "") if attrs[field].present?
    end
  end
end
