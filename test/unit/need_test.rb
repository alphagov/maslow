require_relative '../test_helper'

class NeedTest < ActiveSupport::TestCase

  context "Posting need data" do
    should "serialize Need model to JSON" do
      data = { "role" => "User", "justification" => ["x","y"] }
      need = Need.new(data)
      assert_equal(["justification","role"], need.as_json.keys.sort)
    end

    should "Reject unrecognised fields" do
      data = { "frank" => "Test" }
      assert_raises(ArgumentError) do
        Need.new(data)
      end
    end
  end
end
