require_relative '../test_helper'

class NeedTest < ActiveSupport::TestCase

  context "Posting need data" do
    should "serialize Need model to JSON" do
      data = { "role" => "User", "justifications" => ["x","y"] }
      need = Need.new(data)
      assert_equal(["justifications","role"], need.as_json.keys.sort)
    end

    should "Reject unrecognised fields" do
      data = { "frank" => "Test" }
      assert_raises(ArgumentError) do
        Need.new(data)
      end
    end

    should "not include errors as a serialised field" do
      data = { "role" => "me", "goal" => "stuff", "benefit" => "win" }
      n = Need.new(data)
      n.valid?  # Check this to set errors attribute
      assert_equal ["benefit", "goal", "role"], n.as_json.keys.sort
      assert_equal ["me", "stuff", "win"], n.as_json.values.sort
    end

    should "call the Need API" do
      n = Need.new({})
      GdsApi::NeedApi.any_instance.expects(:create_need).once.with(n)
      n.save
    end
  end
end
