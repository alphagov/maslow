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
        "impact" => "Endangers the health of individuals",
        "justifications" => ["it's something only government does", "the government is legally obliged to provide it"],
        "met_when" => "Winning"
      }
    end

    should "fail with incomplete data" do
      GdsApi::NeedApi.any_instance.expects(:create_need).never

      need_data = {
        "role" => "User",
        "goal" => "do stuff",
        # No benefit
        "organisation_ids" => ["ministry-of-justice"]
      }

      post(:create, need: need_data)
      assert_template :new
    end

    should "post to needs API when data is complete" do
      GdsApi::NeedApi.any_instance.expects(:create_need).with do |req|
        req.to_json == complete_need_data.merge("met_when"=>["Winning"]).to_json
      end
      post(:create, need: complete_need_data)
      assert_redirected_to :action => :index
    end

    should "remove blank entries from justifications" do
      need_data = complete_need_data.merge("justifications" => ["", "it's something only government does"])

      GdsApi::NeedApi.any_instance.expects(:create_need).with(
        responds_with(:justifications, ["it's something only government does"])
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
