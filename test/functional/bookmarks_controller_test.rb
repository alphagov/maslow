require_relative "../integration_test_helper"

class BookmarksControllerTest < ActionController::TestCase
  need_content_item = FactoryBot.create(:need_content_item)

  setup do
    login_as_stub_user
    publishing_api_has_item(need_content_item)
    publishing_api_has_linkables([], document_type: "organisation")
    stub_publishing_api_has_links(
      "content_id" => need_content_item["content_id"],
      "links" => {
        "organisations" => [],
      },
    )
  end

  context "GET bookmarks" do
    should "be successful" do
      stub_user.expects(:bookmarks).returns([need_content_item["content_id"]])

      get :index
      assert_response :success
    end
  end

  context "POST toggle_bookmarks" do
    should "toggle the bookmark" do
      stub_user.expects(:toggle_bookmark).with(need_content_item["content_id"])

      post :toggle, params: {
        "bookmark" => {
          "content_id" => need_content_item["content_id"],
          "redirect_to" => "/foo",
        },
      }
    end

    should "redirect to the correct page" do
      post :toggle, params: {
        "bookmark" => {
          "content_id" => need_content_item["content_id"],
          "redirect_to" => "/needs",
        },
      }
      assert_redirected_to "/needs"

      post :toggle, params: {
        "bookmark" => {
          "content_id" => need_content_item["content_id"],
          "redirect_to" => "/bookmarks",
        },
      }
      assert_redirected_to "/bookmarks"
    end

    should "redirect unknown paths to /needs" do
      post :toggle, params: {
        "bookmark" => {
          "content_id" => need_content_item["content_id]"],
          "redirect_to" => "http://foo.com",
        },
      }
      assert_redirected_to "/needs"
    end
  end
end
