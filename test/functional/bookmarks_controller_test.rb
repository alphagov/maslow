require_relative '../integration_test_helper'

class BookmarksControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::NeedApi

  def need
    {
      "id" => "10001",
      "role" => "parent",
      "goal" => "apply for a primary school place",
      "benefit" => "my child can start school",
      "organisation_ids" => ["department-for-education"],
      "organisations" => [
        {
          "id" => "department-for-education",
          "name" => "Department for Education",
        }
      ],
      "applies_to_all_organisations" => false,
      "justifications" => [
        "it's something only government does",
        "the government is legally obliged to provide it"
      ],
      "impact" => "Has serious consequences for the day-to-day lives of your users",
      "met_when" => [
        "The user applies for a school place"
      ]
    }
  end

  setup do
    login_as_stub_user
    need_api_has_needs([need])
    need_api_has_need(need)
    need_api_has_organisations({})
  end

  context "GET bookmarks" do
    should "be successful" do
      stub_user.expects(:bookmarks).returns([10001])

      get :index
      assert_response :success
    end
  end

  context "POST toggle_bookmarks" do
    should "toggle the bookmark" do
      stub_user.expects(:toggle_bookmark).with(10001)

      post :toggle, {
        "bookmark" => {
          "need_id" => "10001",
          "redirect_to" => "/foo"
        }
      }
    end

    should "redirect to the correct page" do
      post :toggle, {
        "bookmark" => {
          "need_id" => "10001",
          "redirect_to" => "/foo"
        }
      }

      assert_redirected_to "/foo"
    end
  end
end
