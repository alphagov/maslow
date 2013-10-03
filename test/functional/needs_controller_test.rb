require_relative '../integration_test_helper'

class NeedsControllerTest < ActionController::TestCase

  setup do
    login_as stub_user
  end

  context "Posting need data" do

    def complete_need_data
      {
        "role" => "User",
        "goal" => "do stuff",
        "benefit" => "get stuff",
        "organisations" => "me",
        "evidence" => "Blah",
        "impact" => "Nasty",
        "justification" => ["Wanna", "Gotta"],
        "met_when" => "Winning"
      }
    end

    should "fail with incomplete data" do
      need_data = {
        "role" => "User",
        "goal" => "do stuff",
        "benefit" => "get stuff",
        "organisations" => "me"
      }

      post(:create, need: need_data)
      assert_response :unprocessable_entity
      # assert need not posted
    end

    should "post to needs API when data is complete" do
      post(:create, need: complete_need_data)
      assert_response :redirect
      # Assert need posted
    end

    should "remove blank entries from justification" do
      need_data = complete_need_data.merge("justification" => ["", "foo"])

      NeedAPISubmitter.instance.expects(:create).with(
        responds_with(:justification, ["foo"])
      )
      post(:create, need: need_data)
    end

    should "split 'Need is met' criteria into separate parts" do
      need_data = complete_need_data.merge("met_when" => "Foo\nBar\nBaz")
      NeedAPISubmitter.instance.expects(:create).with(
        responds_with(:met_when, ["Foo", "Bar", "Baz"])
      )
      post(:create, need: need_data)
    end

    should "split out CRLF line breaks from 'Need is met' criteria" do
      need_data = complete_need_data.merge("met_when" => "Foo\r\nBar\r\nBaz")
      NeedAPISubmitter.instance.expects(:create).with(
        responds_with(:met_when, ["Foo", "Bar", "Baz"])
      )
      post(:create, need: need_data)
    end
  end

end
