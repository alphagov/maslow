require_relative '../integration_test_helper'

class BookmarkingNeedsTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::Organisations
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as_stub_user
    organisations_api_has_organisations([])

    need_1 = example_need("id" => "10001", "goal" => "apply for a primary school place")
    need_2 = example_need("id" => "10002", "goal" => "find out about becoming a British citizen")
    need_api_has_need_ids([need_1])
    need_api_has_needs([need_1, need_2])
  end

  context "Bookmarking needs" do
    should "add needs to a bookmarks list" do
      visit "/needs"
      click_button "bookmark_10001"
      click_link "Bookmarked needs"

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
