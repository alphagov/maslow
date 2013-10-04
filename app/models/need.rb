require "active_model"

class Need
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Serialization

  FIELDS = ["role", "goal", "benefit", "organisations", "evidence", "impact", "justification", "met_when"]
  attr_accessor *FIELDS

  validates_presence_of ["role", "goal", "benefit"]

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

  def persisted?
    false
  end
end
