require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'

class NeedsControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as stub_user
    need_api_has_organisations(
      "ministry-of-justice" => "Ministry of Justice",
      "competition-commission" => "Competition Commission"
    )
  end

  context "Posting need data" do

    def complete_need_data
      {
        "role" => "User",
        "goal" => "do stuff",
        "benefit" => "get stuff",
        "organisation_ids" => ["ministry-of-justice"],
        "evidence" => "Blah",
        "impact" => "Nasty",
        "justifications" => ["Wanna", "Gotta"],
        "met_when" => "Winning"
      }
    end

    should "fail with incomplete data" do
      need_data = {
        "role" => "User",
        "goal" => "do stuff",
        # No benefit
        "organisation_ids" => ["ministry-of-justice"]
      }

      post(:create, need: need_data)
      assert_response :unprocessable_entity
      # assert need not posted
    end

    should "post to needs API when data is complete" do
      GdsApi::NeedApi.any_instance.expects(:create_need).with(
        is_a(Need)
      )
      post(:create, need: complete_need_data)
      assert_response :redirect
      # Assert need posted
    end

    should "remove blank entries from justifications" do
      need_data = complete_need_data.merge("justifications" => ["", "foo"])

      GdsApi::NeedApi.any_instance.expects(:create_need).with(
        responds_with(:justifications, ["foo"])
      )
      post(:create, need: need_data)
    end

    should "split 'Need is met' criteria into separate parts" do
      need_data = complete_need_data.merge("met_when" => "Foo\nBar\nBaz")
      GdsApi::NeedApi.any_instance.expects(:create_need).with(
        responds_with(:met_when, ["Foo", "Bar", "Baz"])
      )
      post(:create, need: need_data)
    end

    should "split out CRLF line breaks from 'Need is met' criteria" do
      need_data = complete_need_data.merge("met_when" => "Foo\r\nBar\r\nBaz")
      GdsApi::NeedApi.any_instance.expects(:create_need).with(
        responds_with(:met_when, ["Foo", "Bar", "Baz"])
      )
      post(:create, need: need_data)
    end
  end

end
