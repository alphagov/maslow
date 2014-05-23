require_relative '../integration_test_helper'

class BookmarkingNeedsTest < ActionDispatch::IntegrationTest
  def need_1
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

  def need_2
    {
      "id" => "10002",
      "role" => "user",
      "goal" => "find out about becoming a British citizen",
      "benefit" => "i can take the correct steps to apply for citizenship",
      "organisation_ids" => ["home-office", "hm-passport-office"],
      "organisations" => [
        {
          "id" => "home-office",
          "name" => "Home Office",
        },
        {
          "id" => "hm-passport-office",
          "name" => "HM Passport Office",
        }
      ],
      "applies_to_all_organisations" => false,
      "justifications" => [
        "it's something only government does",
        "the government is legally obliged to provide it"
      ],
      "impact" => "Has serious consequences for the day-to-day lives of your users",
      "met_when" => [
        "The user finds information about the citizenship test and the next steps"
      ]
    }
  end

  setup do
    login_as_stub_user
    need_api_has_organisations([])
    need_api_has_need_ids([need_1])
    need_api_has_needs([need_1, need_2])
  end

  context "Bookmarking needs" do
    should "add needs to a bookmarks list" do
      visit "/needs"
      click_button "bookmark_10001"
      click_link "My bookmarked needs"

      assert page.has_content?("10001")
      assert page.has_content?("Apply for a primary school place")
      assert page.has_no_content?("10002")
    end

    should "show bookmarked needs with a star icon" do
      visit "/needs"
      assert page.has_no_css?("#bookmark_10001 .glyphicon-star")

      click_button "bookmark_10001"
      assert page.has_css?("#bookmark_10001 .glyphicon-star")
    end
  end
end
