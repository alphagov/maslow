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

    should "reject non-numeric values in the Contacts field" do
      need_data = complete_need_data.merge("contacts" => "test")
      GdsApi::NeedApi.any_instance.expects(:create_need).never
      post(:create, :need => need_data)
      assert_response 422
    end

    should "reject non-numeric values in the Site Views field" do
      need_data = complete_need_data.merge("site_views" => "test")
      GdsApi::NeedApi.any_instance.expects(:create_need).never
      post(:create, :need => need_data)
      assert_response 422
    end

    should "reject non-numeric values in the Need Views field" do
      need_data = complete_need_data.merge("need_views" => "test")
      GdsApi::NeedApi.any_instance.expects(:create_need).never
      post(:create, :need => need_data)
      assert_response 422
    end

    should "reject non-numeric values in the Need Searches field" do
      need_data = complete_need_data.merge("searched_for" => "test")
      GdsApi::NeedApi.any_instance.expects(:create_need).never
      post(:create, :need => need_data)
      assert_response 422
    end
  end

end
