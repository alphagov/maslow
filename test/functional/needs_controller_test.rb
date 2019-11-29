require_relative "../integration_test_helper"
require "gds_api/publishing_api_v2"

class NeedsControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  def existing_need(options = {})
    defaults = {
      "role" => "person",
      "goal" => "do things",
      "benefit" => "good things",
      "publication_state" => "draft",
    }
    Need.new(defaults.merge(options))
  end

  setup do
    login_as_stub_user
    publishing_api_has_linkables([], document_type: "organisation")
    stub_any_publishing_api_put_content
    stub_any_publishing_api_patch_links
    Need.any_instance.stubs(:organisations).returns([])
  end

  context "GET index" do
    setup do
      publishing_api_has_content(
        [],
        Need.default_options.merge(
          per_page: 50,
        ),
      )
    end

    should "be successful" do
      get :index
      assert_response :success
    end

    should "fetch a list of needs and assign them to the template" do
      # given we're using mocked data, stub the render action so we don't
      # try and render the view. we're only testing here that the variables
      # are actually being assigned correctly.
      @controller.stubs(:render)

      needs_collection = [stub(id: "foo"), stub(id: "bar")]
      Need.expects(:list).returns(needs_collection)

      get :index

      assert_equal %w(foo bar), assigns(:needs).map(&:id)
    end

    context "paginated needs" do
      should "pass the 'page' parameter to Need.list" do
        Need.expects(:list).with("page" => "three")
        get :index, params: { "page" => "three" }
      end
    end

    context "blank query parameter" do
      should "not pass the query parameter on to the need API" do
        Need.expects(:list).with({})
        get(:index, params: { "q" => "" })
      end
    end

    context "searching needs" do
      should "send the search query" do
        Need.expects(:list).with("q" => "citizenship")
        get(:index, params: { "q" => "citizenship" })
      end
    end
  end

  def complete_need_data
    {
      "role" => "User",
      "goal" => "do stuff",
      "benefit" => "get stuff",
      "organisation_ids" => %w(ministry-of-justice),
      "impact" => "Endangers people",
      "justifications" => ["It's something only government does", "The government is legally obliged to provide it"],
      "met_when" => %w(Winning Awesome),
    }
  end

  context "POST create" do
    setup do
      login_as_stub_editor
    end

    should "fail with incomplete data" do
      Need.any_instance.expects(:save).never

      need_data = {
        "role" => "User",
        "goal" => "do stuff",
        # No benefit
        "organisation_ids" => %w(ministry-of-justice),
      }

      post(:create, params: { need: need_data })
      assert_template :new
    end

    should "return a 500 response if save fails" do
      Need.any_instance.expects(:save).returns(false)

      need_data = {
        "role" => "User",
        "goal" => "Do Stuff",
        "benefit" => "test",
      }
      post(:create, params: { need: need_data })

      assert_response 500
    end

    should "remove blank entries from justifications" do
      need_data = complete_need_data.merge(
        "justifications" => ["", "It's something only government does"],
      )

      GdsApi::PublishingApiV2.any_instance.expects(:put_content).with do |_, body|
        assert_equal body[:details]["justifications"],
                     ["It's something only government does"]
      end

      post(:create, params: { need: need_data })
    end

    should "add a blank value to met_when if a 'Add criteria' is requested" do
      post(:create, params: { criteria_action: "Add criteria", need: complete_need_data })

      assert_response 200
      assert_equal ["Winning", "Awesome", ""], assigns[:need].met_when
    end

    should "create the need and redirect to add new need if 'add_new' provided" do
      Need.any_instance.expects(:save).returns(true)
      post(:create, params: { add_new: "", need: complete_need_data })

      assert_redirected_to new_need_path
    end

    context "CSRF protection" do
      should "return a 403 status when not a verified request" do
        # as allow_forgery_protection is disabled in the test environment, we're
        # stubbing the verified_request? method from
        # ActionController::RequestForgeryProtection::ClassMethods to return false
        # in order to test our override of the verify_authenticity_token method
        @controller.stubs(:verified_request?).returns(false)

        post :create, params: { need: complete_need_data }

        assert_response 403
        assert_equal "Invalid authenticity token", response.body
      end
    end

    should "stop viewers from creating needs" do
      login_as_stub_user
      post(:create, params: { need: complete_need_data })
      assert_redirected_to needs_path
    end
  end

  context "GET show" do
    context "given a valid need" do
      setup do
        @stub_need = Need.new(
          "role" => "person",
          "goal" => "do things",
          "benefit" => "good things",
          "publication_state": "draft",
        )

        @stub_need.stubs(:content_items_meeting_this_need).returns([])

        Need.expects(:find).with(@stub_need.content_id).returns(@stub_need)
      end

      should "make a successful request" do
        get :show, params: { content_id: @stub_need.content_id }

        assert_response :ok
      end

      should "use the show template" do
        get :show, params: { content_id: @stub_need.content_id }

        assert_template :show
      end

      should "assign the need to the form" do
        get :show, params: { content_id: @stub_need.content_id }

        assert_equal @stub_need, assigns[:need]
      end
    end

    should "404 if the need doesn't exist" do
      content_id = SecureRandom.uuid
      Need.expects(:find).with(content_id).raises(Need::NotFound.new(content_id))
      get :show, params: { content_id: content_id }

      assert_response :not_found
    end
  end

  context "GET revisions" do
    context "given a valid need" do
      setup do
        @stub_need = existing_need

        Need.expects(:find).with(@stub_need.content_id).returns(@stub_need)
        @stub_need.expects(:revisions).returns([])
      end

      should "make a successful request" do
        get :revisions, params: { content_id: @stub_need.content_id }

        assert_response :ok
      end

      should "use the revisions template" do
        get :revisions, params: { content_id: @stub_need.content_id }

        assert_template :revisions
      end

      should "assign the need to the form" do
        get :revisions, params: { content_id: @stub_need.content_id }

        assert_equal @stub_need, assigns[:need]
      end
    end

    should "404 if the need doesn't exist" do
      content_id = SecureRandom.uuid
      Need.expects(:find).with(content_id).raises(Need::NotFound.new(content_id))
      get :revisions, params: { content_id: content_id }

      assert_response :not_found
    end
  end

  context "GET edit" do
    setup do
      login_as_stub_editor
    end

    context "given a valid need" do
      setup do
        @stub_need = existing_need
      end

      should "display the need form" do
        Need.expects(:find).with(@stub_need.content_id).returns(@stub_need)
        get :edit, params: { content_id: @stub_need.content_id }

        assert_response :ok
        assert_equal "do things", assigns[:need].goal
      end
    end

    should "404 if the need doesn't exist" do
      content_id = SecureRandom.uuid
      Need.expects(:find).with(content_id).raises(Need::NotFound.new(content_id))
      get :edit, params: { content_id: content_id }
      assert_response :not_found
    end

    should "stop viewers from editing needs" do
      login_as_stub_user
      get :edit, params: { content_id: SecureRandom.uuid }
      assert_redirected_to needs_path
    end
  end

  def base_need_fields
    {
      "role" => "person",
      "goal" => "do things",
      "benefit" => "good things",
    }
  end

  context "POST update" do
    setup do
      login_as_stub_editor
    end

    should "404 if need not found" do
      content_id = SecureRandom.uuid
      Need.expects(:find).with(content_id).raises(Need::NotFound.new(content_id))
      put :update, params: {
        content_id: content_id,
        need: { goal: "do things" },
      }
      assert_response :not_found
    end

    should "redisplay with a 422 if need is invalid" do
      need = existing_need
      Need.expects(:find).with(need.content_id).returns(need)
      need.expects(:save).never

      put :update, params: {
        content_id: need.content_id,
        need: base_need_fields.merge("goal" => ""),
      }
      assert_response 422
    end

    should "save the need if valid and redirect to show it" do
      need = existing_need
      Need.expects(:find).with(need.content_id).returns(need)
      need.expects(:save).returns(true)

      put :update, params: {
        content_id: need.content_id,
        need: base_need_fields.merge("benefit" => "be awesome"),
      }
      assert_redirected_to need_path(need.content_id)
    end

    should "update the need and redirect to add new need if 'add_new' provided" do
      need = existing_need
      Need.expects(:find).with(need.content_id).returns(need)
      need.expects(:save).returns(true)

      put :update, params: {
        content_id: need.content_id,
        need: base_need_fields.merge("benefit" => "be awesome"),
        add_new: "",
      }
      assert_redirected_to new_need_path
    end

    should "leave met when criteria unchanged" do
      need = existing_need
      Need.expects(:find).with(need.content_id).returns(need)
      # Forcing the validity check to false so we redisplay the form
      need.expects(:valid?).returns(false)
      need.expects(:save).never

      put :update, params: {
        content_id: need.content_id,
        need: base_need_fields.merge("met_when" => ["something", "something else"]),
      }

      assert_response 422
      assert_equal ["something", "something else"], assigns[:need].met_when
    end

    should "return a 422 response if save fails" do
      need = existing_need
      Need.expects(:find).with(need.content_id).returns(need)
      need.expects(:save).returns(false)

      need_data = {
        "role" => "User",
        "goal" => "Do Stuff",
        "benefit" => "test",
      }
      put(:update, params: { content_id: need.content_id, need: need_data })

      assert_response 500
    end

    should "stop viewers from updating needs" do
      login_as_stub_user
      put(:update, params: { content_id: SecureRandom.uuid, need: {} })
      assert_redirected_to needs_path
    end
  end

  context "POST publish" do
    setup do
      login_as_stub_admin
    end

    context "given a draft need" do
      setup do
        @stub_need = Need.new(publication_state: "draft")
      end

      should "publish the need" do
        # not testing the save method here
        @stub_need.stubs(:save).returns(true)
        Need.stubs(:find).with(@stub_need.content_id).returns(@stub_need)
        @stub_need.expects(:publish)

        post :actions, params: { need_action: "publish", content_id: @stub_need.content_id }
      end
    end
  end

  context "deleting met_when criteria" do
    setup do
      login_as_stub_editor
    end

    should "remove the only value" do
      need = complete_need_data.merge("met_when" => %w[Winning])
      post(:create, params: { delete_criteria: "0", need: need })

      assert_response 200
      assert_equal [], assigns[:need].met_when
    end

    should "remove one of many values" do
      data = complete_need_data.merge(
        "met_when" => %w(0 1 2 3),
      )
      post(:create, params: { delete_criteria: "2", need: data })

      assert_response 200
      assert_equal %w(0 1 3), assigns[:need].met_when
    end

    should "do nothing if an invalid request is made" do
      post(:create, params: { delete_criteria: "foo", need: complete_need_data })

      assert_response 200
      assert_equal %w(Winning Awesome), assigns[:need].met_when
    end
  end

  context "POST unpublish" do
    setup do
      login_as_stub_editor
      @need = existing_need
      Need.stubs(:find).with(@need.content_id).returns(@need)

      @duplicate_need = existing_need
      Need.stubs(:find).with(@duplicate_need.content_id).returns(@duplicate_need)
    end

    should "unpublish the need" do
      @need.expects(:unpublish).returns(true)

      put :actions, params: {
            need_action: "unpublish",
            content_id: @need.content_id,
            need: { duplicate_of: @duplicate_need.content_id },
          }
    end

    should "redirect to the need with a success message once complete" do
      @need.stubs(:unpublish).returns(true)

      put :actions, params: {
            need_action: "unpublish",
            content_id: @need.content_id,
            need: { duplicate_of: @duplicate_need.content_id },
          }

      assert_not @controller.flash[:error]
      assert_equal "Need withdrawn", @controller.flash[:notice]
      assert_redirected_to need_path(@need.content_id)
    end

    should "not be able to edit a need closed as a duplicate" do
      @duplicate_need.publication_state = "unpublished"

      get :edit, params: { content_id: @duplicate_need.content_id }

      assert_equal "Closed needs cannot be edited", @controller.flash[:notice]
      assert_response 303
    end

    should "stop viewers from marking needs as duplicates" do
      login_as_stub_user
      put :actions, params: {
            need_action: "unpublish",
            content_id: @need.content_id,
            duplicate_of: @duplicate_need.content_id,
          }
      assert_redirected_to needs_path
    end
  end

  context "GET actions" do
    setup do
      login_as_stub_editor
      @stub_need = existing_need(publication_state: "draft")
      Need.expects(:find).with(@stub_need.content_id).returns(@stub_need)
    end

    should "be successful" do
      get :actions, params: { content_id: @stub_need.content_id }
      assert_response :success
    end
  end
end
