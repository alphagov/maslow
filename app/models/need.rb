require "active_model"

class Need
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :role, :goal, :benefit, :organisations, :evidence, :impact, :justification

  validates_presence_of :role, :goal, :benefit, :organisations, :evidence, :impact, :justification

  def persisted?
    false
  end
end
