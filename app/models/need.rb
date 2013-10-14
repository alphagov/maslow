require "active_model"

class Need
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Serialization

  JUSTIFICATIONS = [
    "it's something only government does",
    "the government is legally obliged to provide it",
    "it's inherent to a person's or an organisation's rights and obligations",
    "it's something that people can do or it's something people need to know before they can do something that's regulated by/related to government",
    "there is clear demand for it from users",
    "it's something the government provides/does/pays for",
    "it's straightforward advice that helps people to comply with their statutory obligations"
  ]
  IMPACT = [
    "Endangers the health of individuals",
    "Has serious consequences for the day-to-day lives of your users",
    "Annoys the majority of your users. May incur fines",
    "Noticed by the average member of the public",
    "Noticed by an expert audience",
    "No impact"
  ]
  FIELDS = ["role", "goal", "benefit", "organisation_ids", "impact", "justifications", "met_when"]
  attr_accessor *FIELDS

  validates_presence_of ["role", "goal", "benefit"]
  validates :impact, inclusion: { in: IMPACT }, allow_blank: true
  validates_each :justifications do |record, attr, value|
    record.errors.add(attr, "must contain a known value") unless (value.nil? || value.all? { |v| JUSTIFICATIONS.include? v })
  end

  def initialize(attrs)
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
    FIELDS.each_with_object({}) do |field, hash|
      hash[field] = send(field) unless send(field).nil?
    end
  end

  def save
    Maslow.need_api.create_need(self)
  end

  def persisted?
    false
  end
end
