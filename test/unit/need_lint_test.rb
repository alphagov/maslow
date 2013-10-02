require 'test_helper'

# The lint test makes sure that Need will act like an ActiveModel
# instance
class NeedLintTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  def setup
    @model = Need.new
  end
end
