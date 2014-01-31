require_relative '../integration_test_helper'

class MaslowNeedBookmarkletControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as stub_user
    need_api_has_organisations({})
  end

  context "GET maslow_need_bookmarklet" do
    setup do
      need_api_has_needs([])
    end

    should "be successful" do
      get :maslow_need_bookmarklet
      assert_response :success
    end
  end
end
