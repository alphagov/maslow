require_relative '../integration_test_helper'

class BookmarkletControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as stub_user
    need_api_has_organisations({})
  end

  context "GET bookmarklet" do
    setup do
      need_api_has_needs([])
    end

    should "be successful" do
      get :bookmarklet
      assert_response :success
    end
  end
end
