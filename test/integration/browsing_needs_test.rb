require_relative "../integration_test_helper"
require "gds_api/test_helpers/publishing_api"

class BrowsingNeedsTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::PublishingApi
  include NeedHelper

  setup do
    login_as_stub_user
  end

  context "viewing the list of needs" do
    should "display a table of all the needs" do
      need_content_items = FactoryBot.create_list(:need_content_item, 3)
      stub_publishing_api_has_linkables([], document_type: "organisation")
      stub_publishing_api_has_content(
        need_content_items,
        Need.default_options.merge(
          per_page: 50,
        ),
      )
      need_content_items.each do |need_content_item|
        stub_publishing_api_has_links(
          content_id: need_content_item["content_id"],
          links: {
            organisations: [],
          },
        )
      end

      visit "/needs"

      assert page.has_content?("All needs")

      within "table#needs" do
        need_content_items.each_with_index do |content_item, index|
          within "tbody tr:nth-of-type(#{index + 1})" do
            assert page.has_content?(format_need_goal(content_item["details"]["goal"]))
          end
        end
      end
    end
  end

  should "be able to navigate between pages of results" do
    content = create_list(:need_content_item, 9)
    options = Need.default_options.merge(per_page: 3)
    Need.stubs(:default_options).returns(options)
    stub_publishing_api_has_content(content, options)
    stub_publishing_api_has_content(content, options.merge(page: 2))
    stub_publishing_api_has_content(content, options.merge(page: 3))

    stub_publishing_api_has_linkables([], document_type: "organisation")

    get_links_url = %r{\A#{Plek.find('publishing-api')}/v2/links}
    stub_request(:get, get_links_url).to_return(
      body: { links: { organisations: [] } }.to_json,
    )

    visit "/needs"

    # assert the content on page 1
    within "table#needs" do
      content[0..2].each do |need_content|
        assert page.has_content?(format_need_goal(need_content["details"]["goal"]))
      end
    end

    within ".pagination" do
      assert page.has_selector?("li.active", text: "1")

      assert page.has_link?("2", href: "/needs?page=2")

      assert page.has_no_link?("‹ Prev")
      assert page.has_link?("Next ›", href: "/needs?page=2")

      click_on "Next ›"
    end

    # assert the content on page 2
    within "table#needs" do
      content[3..5].each do |need_content|
        assert page.has_content?(format_need_goal(need_content["details"]["goal"]))
      end
    end

    within ".pagination" do
      assert page.has_selector?("li.active", text: "2")

      assert page.has_link?("1", href: "/needs")
      assert page.has_link?("3", href: "/needs?page=3")

      assert page.has_link?("‹ Prev", href: "/needs")
      assert page.has_link?("Next ›", href: "/needs?page=3")

      click_on "Next ›"
    end

    # assert the content on page 3
    within "table#needs" do
      content[6..8].each do |need_content|
        assert page.has_content?(format_need_goal(need_content["details"]["goal"]))
      end
    end

    within ".pagination" do
      assert page.has_selector?("li.active", text: "3")

      assert page.has_link?("1", href: "/needs")
      assert page.has_link?("2", href: "/needs?page=2")

      assert page.has_no_link?("Next ›")
      assert page.has_link?("‹ Prev", href: "/needs?page=2")
    end
  end
end
