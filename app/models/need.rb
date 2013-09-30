require "active_model"

class Need
  extend  ActiveModel::Naming
  include ActiveModel::Translation
  include ActiveModel::Conversion

  def persisted?
    false
  end
end
