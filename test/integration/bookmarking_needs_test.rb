require_relative '../integration_test_helper'

class BookmarkingNeedsTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::PublishingApiV2

  setup do
    login_as_stub_user

    @need_content_item = create(:need_content_item,
                                content_id: "c1573261-b973-467f-aa57-5a24435fa295", # Randomly generated.
                                details: {
                                  goal: "Apply for a primary school place",
                                  need_id: 10001,
                                })

    publishing_api_has_linkables([], document_type: "organisation")
    publishing_api_has_content(
      [@need_content_item],
      Need.default_options.merge(
        per_page: 50
      )
    )
    publishing_api_has_links(
      content_id: @need_content_item["content_id"],
      links: {}
    )
    publishing_api_has_item(@need_content_item)
  end

  context "Bookmarking needs" do
    should "add needs to a bookmarks list" do
      visit "/needs"
      click_button "bookmark_c1573261-b973-467f-aa57-5a24435fa295"
      click_link "Bookmarked needs"

      assert page.has_content?("10001")
      assert page.has_content?("Apply for a primary school place")
      assert page.has_no_content?("10002")
    end

    should "show bookmarked needs with a star icon" do
      visit "/needs"
      assert page.has_no_css?("#bookmark_c1573261-b973-467f-aa57-5a24435fa295 .glyphicon-star")

      click_button "bookmark_c1573261-b973-467f-aa57-5a24435fa295"
      assert page.has_css?("#bookmark_c1573261-b973-467f-aa57-5a24435fa295 .glyphicon-star")
    end
  end
end
