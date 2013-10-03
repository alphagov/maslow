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

    should "split 'Need is met' criteria into separate parts" do
      Need.expects(:new).with("met_when" => ["Foo.","Bar","Baz"])
      post(:create, need: { met_when: "Foo.\nBar\nBaz" })
    end

    should "split out CRLF line breaks from 'Need is met' criteria" do
      Need.expects(:new).with("met_when" => ["Foo.","Bar","Baz"])
      post(:create, need: { met_when: "Foo.\r\nBar\r\nBaz\r\n" })
    end
  end

end
