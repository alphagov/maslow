require "active_model"

class Need
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :role

  validates_presence_of :role

  def persisted?
    false
  end
end
