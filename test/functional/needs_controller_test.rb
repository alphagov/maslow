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
      should "send the organisation id" do
        GdsApi::NeedApi.any_instance.expects(:needs).with({"organisation_id" => "test"})
        get(:index, "organisation_id" => "test")
      end

      should "not send any other values" do
        GdsApi::NeedApi.any_instance.expects(:needs).with({})
        get(:index, "fake" => "fake")
      end
    end

    context "paginated needs" do
      should "pass the 'page' parameter to the Need API" do
        GdsApi::NeedApi.any_instance.expects(:needs).with("page" => "three")
        get :index, "page" => "three"
      end
    end

    context "blank query parameter" do
      should "not pass the query parameter on to the need API" do
        GdsApi::NeedApi.any_instance.expects(:needs).with({})
        get(:index, "q" => "")
      end
    end

    context "searching needs" do
      should "send the search query" do
        GdsApi::NeedApi.any_instance.expects(:needs).with({"q" => "citizenship"})
        get(:index, "q" => "citizenship")
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

      mock_need.expects(:need_id).returns(1)

      post(:create, need: complete_need_data)
      assert_redirected_to need_path(:id => 1)
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
      ).returns("id"=>100001)

      post(:create, need: need_data)
    end

    should "add a blank value to met_when if a 'Add criteria' is requested" do
      post(:create, { criteria_action: "Add criteria", need: complete_need_data })

      assert_response 200
      assert_equal ["Winning", "Awesome", ""], assigns[:need].met_when
    end

    context "CSRF protection" do
      should "return a 403 status when not a verified request" do
        # as allow_forgery_protection is disabled in the test environment, we're
        # stubbing the verified_request? method from
        # ActionController::RequestForgeryProtection::ClassMethods to return false
        # in order to test our override of the verify_authenticity_token method
        @controller.stubs(:verified_request?).returns(false)

        post :create, need: complete_need_data

        assert_response 403
        assert_equal "Invalid authenticity token", response.body
      end
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

        # stub the artefacts method so that we don't make calls to
        # the content api. we aren't really testing the view behaviour
        # here so just return an empty array
        @stub_need.expects(:artefacts).returns([])

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

  context "GET revisions" do
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
        get :revisions, id: 100001

        assert_response :ok
      end

      should "use the revisions template" do
        get :revisions, id: 100001

        assert_template :revisions
      end

      should "assign the need to the form" do
        get :revisions, id: 100001

        assert_equal @stub_need, assigns[:need]
      end
    end

    should "404 if the need doesn't exist" do
      Need.expects(:find).with(100001).raises(Need::NotFound.new(100001))
      get :revisions, :id => 100001

      assert_response :not_found
    end

    should "reject non-numeric IDs" do
      Need.expects(:find).never
      get :revisions, :id => "coffee"

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
        assert_equal need_path(:id => 100001), assigns[:target]
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

  context "PUT descope" do
    context "given a valid need without a set value for in_scope" do
      setup do
        @stub_need = Need.new({
            "id" => 100001,
            "role" => "person",
            "goal" => "do things",
            "benefit" => "good things",
            "in_scope" => nil
          }, true)
        Need.expects(:find).with(100001).returns(@stub_need)
      end

      should "set the in_scope attribute to false" do
        # not testing the save method here
        @stub_need.stubs(:save_as).returns(true)

        @stub_need.expects(:in_scope=).with(false)

        put :descope, id: 100001
      end

      should "save the need as the current user" do
        @stub_need.expects(:save_as).with do |user|
          user.name = stub_user.name
          user.email = stub_user.email
          user.uid = stub_user.uid
        end.returns(true)

        put :descope, id: 100001
      end

      should "redirect to the need with a success message once complete" do
        @stub_need.stubs(:save_as).returns(true)

        put :descope, id: 100001

        refute @controller.flash[:error]
        assert_equal "Need has been marked as out of scope", @controller.flash[:notice]
        assert_redirected_to need_path(@stub_need)
      end

      should "redirect to the need with an error if the save fails" do
        @stub_need.stubs(:save_as).returns(false)

        put :descope, id: 100001

        refute @controller.flash[:notice]
        assert_equal "We had a problem marking the need as out of scope", @controller.flash[:error]
        assert_redirected_to need_path(@stub_need)
      end
    end

    context "given a valid need already marked as out of scope" do
      setup do
        @stub_need = Need.new({
            "id" => 100001,
            "role" => "person",
            "goal" => "do things",
            "benefit" => "good things",
            "in_scope" => false
          }, true)
        Need.expects(:find).with(100001).returns(@stub_need)
      end

      should "redirect to the need with an error" do
        put :descope, id: 100001

        refute @controller.flash[:notice]
        assert_equal "This need has already been marked as out of scope", @controller.flash[:error]
        assert_redirected_to need_path(@stub_need)
      end
    end

    should "404 if a need isn't found" do
      Need.expects(:find).with(100001).raises(Need::NotFound.new(100001))

      put :descope, id: 100001

      assert_response :not_found
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

  context "PUT closed" do
    setup do
      @need = Need.new(base_need_fields.merge("id" => 100002), true)  # duplicate
      Need.expects(:find).with(100002).returns(@need)
    end

    should "call duplicate_of with the correct value" do
      # not testing the save method here
      @need.stubs(:close_as).returns(true)

      @need.expects(:duplicate_of=).with("100001")

      put :closed,
          :id => "100002",
          :need => { :duplicate_of => 100001 }
    end

    should "close the need and redirect to show it" do
      @need.expects(:close_as).with do |user|
        user.name = stub_user.name
        user.email = stub_user.email
        user.uid = stub_user.uid
      end.returns(true)

      put :closed,
          :id => "100002",
          :need => { :duplicate_of => 100001 }
    end

    should "redirect to the need with a success message once complete" do
      @need.stubs(:close_as).returns(true)

      put :closed,
          :id => "100002",
          :need => { :duplicate_of => 100001 }

      refute @controller.flash[:error]
      assert_equal "Need closed as a duplicate of 100001", @controller.flash[:notice]
      assert_redirected_to need_path(100002)
    end

    should "not be able to edit a need closed as a duplicate" do
      @need.duplicate_of = "100002"
      get :edit,
          :id => "100002"
      assert_equal "Closed needs cannot be edited", @controller.flash[:notice]
      assert_response 303
    end

    should "display an error if the duplicate_of id is invalid" do
      @need.expects(:valid?).returns(false)

      put :closed,
          :id => "100002",
          :need => { :duplicate_of => 1 }

      refute @controller.flash[:notice]
      assert_equal "The Need ID entered is invalid", @controller.flash[:error]

      assert_response 422
    end

    should "return a 422 response if save fails" do
      @need.expects(:close_as).returns(false)

      put :closed,
          :id => "100002",
          :need => { :duplicate_of => 100000 }

      refute @controller.flash[:notice]
      assert_equal "There was a problem closing the need as a duplicate", @controller.flash[:error]

      assert_response 422
    end
  end
end
