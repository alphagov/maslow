require_relative '../integration_test_helper'

class BookmarkletControllerTest < ActionController::TestCase
  setup do
    login_as stub_user
  end

  context "GET bookmarklet" do
    should "be successful" do
      get :bookmarklet
      assert_response :success
    end
  end
end
