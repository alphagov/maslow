require_relative '../integration_test_helper'

class BookmarksControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as stub_user
    need_api_has_needs([
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
    ])
      need_api_has_need(
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
      )
      need_api_has_organisations({})
    end

    context "GET bookmarks" do
      should "be successful" do
        stub_user.expects(:bookmarks).returns([10001])

        get :index
        assert_response :success
      end
    end

    context "POST bookmarks" do
      should "add needs to the bookmarks" do
        bookmarks = [10002]
        stub_user.expects(:bookmarks).returns(bookmarks)
        stub_user.expects(:save!)

        post :create, {
          "bookmark" => {
            "need_id" => "10001",
            "redirect_to" => "/foo"
          }
        }

        assert_equal [10002,10001], bookmarks
      end

      should "remove needs from bookmarks" do
        bookmarks = [10001,10002]
        stub_user.expects(:bookmarks).returns(bookmarks)
        stub_user.expects(:save!)

        post :create, {
          "bookmark" => {
            "need_id" => "10001",
            "redirect_to" => "/foo"
          }
        }

        assert_equal [10002], bookmarks
      end

      should "redirect to the correct page" do
        post :create, {
          "bookmark" => {
            "need_id" => "10001",
            "redirect_to" => "/foo"
          }
        }

        assert_redirected_to "/foo"
      end
    end
  end
