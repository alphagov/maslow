require "active_model"

class Need
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :role, :goal, :benefit, :organisations, :evidence, :impact, :justification, :met_when

  validates_presence_of :role, :goal, :benefit, :organisations, :evidence, :impact, :justification, :met_when

  def persisted?
    false
  end
end
