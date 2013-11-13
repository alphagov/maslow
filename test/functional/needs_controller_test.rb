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

  context "GET new" do
    should "target the new need endpoint" do
      get :new
      assert_equal "/needs", assigns[:target]
    end
  end

  context "POST create" do

    def complete_need_data
      {
        "role" => "User",
        "goal" => "do stuff",
        "benefit" => "get stuff",
        "organisation_ids" => ["ministry-of-justice"],
        "impact" => "Endangers people",
        "justifications" => ["It's something only government does", "The government is legally obliged to provide it"],
        "met_when" => ["Winning","Awesome"]
      }
    end

    should "fail with incomplete data" do
      Need.any_instance.expects(:save_as).never

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
      mock_need = stub(:valid? => true)

      Need.expects(:new).with(has_entries(complete_need_data))
        .returns(mock_need)

      mock_need.expects(:save_as).with do |user|
        user.name = stub_user.name
        user.email = stub_user.email
        user.uid = stub_user.uid
      end.returns(true)

      post(:create, need: complete_need_data)
      assert_redirected_to :action => :index
    end

    should "return a 422 response if save fails" do
      Need.any_instance.expects(:save_as).returns(false)

      need_data = {
        "role" => "User",
        "goal" => "Do Stuff",
        "benefit" => "test"
      }
      post(:create, need: need_data)

      assert_response 422
    end

    should "remove blank entries from justifications" do
      need_data = complete_need_data.merge("justifications" => ["", "It's something only government does"])

      GdsApi::NeedApi.any_instance.expects(:create_need).with(
        has_entry("justifications", ["It's something only government does"])
      )
      post(:create, need: need_data)
    end

    should "add a blank value to met_when if a 'Add criteria' is requested" do
      post(:create, { criteria_action: "Add criteria", need: complete_need_data })

      assert_response 200
      assert_equal ["Winning", "Awesome", ""], assigns[:need].met_when
    end

  end

  context "GET show" do
    context "given a valid need" do
      setup do
        @stub_need = Need.new({
          "id" => 100001,
          "role" => "person",
          "goal" => "do things",
          "benefit" => "good things"
        }, true)

        Need.expects(:find).with(100001).returns(@stub_need)
      end

      should "make a successful request" do
        get :show, id: 100001

        assert_response :ok
      end

      should "use the show template" do
        get :show, id: 100001

        assert_template :show
      end

      should "assign the need to the form" do
        get :show, id: 100001

        assert_equal @stub_need, assigns[:need]
      end
    end

    should "404 if the need doesn't exist" do
      Need.expects(:find).with(100001).raises(Need::NotFound.new(100001))
      get :show, :id => 100001

      assert_response :not_found
    end

    should "reject non-numeric IDs" do
      Need.expects(:find).never
      get :show, :id => "coffee"

      assert_response :not_found
    end
  end

  context "GET edit" do
    context "given a valid need" do
      setup do
        @stub_need = Need.new({
          "id" => 100001,
          "role" => "person",
          "goal" => "do things",
          "benefit" => "good things"
        }, true)
      end

      should "display the need form" do
        Need.expects(:find).with(100001).returns(@stub_need)
        get :edit, :id => "100001"

        assert_response :ok
        assert_equal "do things", assigns[:need].goal
        assert_equal "/needs/100001", assigns[:target]
      end
    end

    should "404 if the need doesn't exist" do
      Need.expects(:find).with(100001).raises(Need::NotFound.new(100001))
      get :edit, :id => 100001
      assert_response :not_found
    end

    should "reject non-numeric IDs" do
      Need.expects(:find).never
      get :edit, :id => "coffee"
      assert_response :not_found
    end
  end

  context "PUT update" do
    def base_need_fields
      {
        "role" => "person",
        "goal" => "do things",
        "benefit" => "good things"
      }
    end

    def stub_need
      Need.new(base_need_fields.merge("id" => 100001), true)  # existing need
    end

    should "404 if need not found" do
      Need.expects(:find).with(100001).raises(Need::NotFound.new(100001))
      post :update, :id => "100001", :need => { :goal => "do things" }
      assert_response :not_found
    end

    should "redisplay with a 422 if need is invalid" do
      need = stub_need
      Need.expects(:find).with(100001).returns(need)
      need.expects(:save_as).never

      post :update,
           :id => "100001",
           :need => base_need_fields.merge(:goal => "")
      assert_response 422
    end

    should "save the need if valid and redirect to show it" do
      need = stub_need
      Need.expects(:find).with(100001).returns(need)
      need.expects(:save_as).with(is_a(User)).returns(true)

      post :update,
           :id => "100001",
           :need => base_need_fields.merge(:benefit => "be awesome")
      assert_redirected_to need_path(100001)
    end

    should "leave met when criteria unchanged" do
      need = stub_need
      Need.expects(:find).with(100001).returns(need)
      # Forcing the validity check to false so we redisplay the form
      need.expects(:valid?).returns(false)
      need.expects(:save_as).never

      post :update,
           :id => "100001",
           :need => base_need_fields.merge(:met_when => ["something", "something else"])

      assert_response 422
      assert_equal ["something", "something else"], assigns[:need].met_when
    end

    should "return a 422 response if save fails" do
      need = stub_need
      Need.expects(:find).with(100001).returns(need)
      need.expects(:save_as).returns(false)

      need_data = {
        "role" => "User",
        "goal" => "Do Stuff",
        "benefit" => "test"
      }
      post(:update, id: 100001, need: need_data)

      assert_response 422
    end
  end

  context "deleting met_when criteria" do
    should "remove the only value" do
      need = complete_need_data.merge("met_when" => ["Winning"])
      post(:create, { delete_criteria: "0", need: need })

      assert_response 200
      assert_equal [], assigns[:need].met_when
    end

    should "remove one of many values" do
      data = complete_need_data.merge({
        "met_when" => ["0","1","2","3"]
      })
      post(:create, { delete_criteria: "2", need: data })

      assert_response 200
      assert_equal ["0","1","3"], assigns[:need].met_when
    end

    should "do nothing if an invalid request is made" do
      post(:create, { delete_criteria: "foo", need: complete_need_data })

      assert_response 200
      assert_equal ["Winning", "Awesome"], assigns[:need].met_when
    end
  end

end
