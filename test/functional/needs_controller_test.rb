require_relative '../integration_test_helper'

class NeedsControllerTest < ActionController::TestCase

  setup do
    login_as stub_user
  end

  context "Posting need data" do
    should "pass form values into the model" do
      Need.expects(:new).with("role" => "User")
      post(:create, need: { role: "User" })
    end

    should "remove blank entries from justification" do
      Need.expects(:new).with("role" => "User", "justification" => ["x","y"])
      post(:create, need: { role: "User", justification: ["","x","y"] })
    end
  end

end
