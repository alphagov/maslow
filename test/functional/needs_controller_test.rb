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

  context "GET index" do
    setup do
      need_api_has_needs([])
    end

    should "be successful" do
      get :index
      assert_response :success
    end

    should "fetch needs from the need api and assign them to the template" do
      # given we're using mocked data, stub the render action so we don't
      # try and render the view. we're only testing here that the variables
      # are actually being assigned correctly.
      @controller.stubs(:render)

      needs_collection = [
        OpenStruct.new(id: "foo"),
        OpenStruct.new(id: "bar")
      ]
      GdsApi::NeedApi.any_instance.expects(:needs).returns(needs_collection)

      get :index

      assert_equal ["foo", "bar"], assigns(:needs).map(&:id)
    end
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

    should "legislation free text remains unchanged" do
      need_data = complete_need_data.merge("legislation" => "link#1\nlink#2")
      GdsApi::NeedApi.any_instance.expects(:create_need).with(
        responds_with(:legislation, "link#1\nlink#2")
      )
      post(:create, need: need_data)
    end

    should "reject non-numeric values in the Contacts field" do
      need_data = complete_need_data.merge("monthly_user_contacts" => "test")
      GdsApi::NeedApi.any_instance.expects(:create_need).never
      post(:create, :need => need_data)
      assert_response 422
    end

    should "reject non-numeric values in the Site Views field" do
      need_data = complete_need_data.merge("monthly_site_views" => "test")
      GdsApi::NeedApi.any_instance.expects(:create_need).never
      post(:create, :need => need_data)
      assert_response 422
    end

    should "reject non-numeric values in the Need Views field" do
      need_data = complete_need_data.merge("monthly_need_views" => "test")
      GdsApi::NeedApi.any_instance.expects(:create_need).never
      post(:create, :need => need_data)
      assert_response 422
    end

    should "reject non-numeric values in the Need Searches field" do
      need_data = complete_need_data.merge("monthly_searches" => "test")
      GdsApi::NeedApi.any_instance.expects(:create_need).never
      post(:create, :need => need_data)
      assert_response 422
    end

    should "accept blank values in the numeric fields" do
      need_data = complete_need_data.merge("monthly_user_contacts" => "", "monthly_searches" => "",
                                           "monthly_need_views" => "", "monthly_site_views" => "")
      GdsApi::NeedApi.any_instance.expects(:create_need).with do |need|
        need.as_json["monthly_user_contacts"].nil? &&
        need.as_json["monthly_site_views"].nil? &&
        need.as_json["monthly_need_views"].nil? &&
        need.as_json["monthly_searches"].nil?
      end
      post(:create, :need => need_data)
      assert_redirected_to :action => :index
    end
  end

  context "filtering needs" do
    should "sends the organisation id" do
      GdsApi::NeedApi.any_instance.expects(:needs).with({"organisation_id" => "test"})
      get(:index, "organisation_id" => "test")
    end

    should "not send any other values" do
      GdsApi::NeedApi.any_instance.expects(:needs).with({})
      get(:index, "fake" => "fake")
    end
  end

end
