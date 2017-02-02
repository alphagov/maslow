require_relative '../integration_test_helper'
require 'gds_api/test_helpers/organisations'
require 'gds_api/test_helpers/publishing_api_v2'

class BookmarkletTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user
    organisations_api_has_organisations([])
    publishing_api_has_content(
      [],
      Need.default_options.merge(
        per_page: 50
      )
    )
  end

  context "on the navbar" do
    should "link to 'Maslow need' bookmarklet" do
      visit "/needs"
      assert page.has_link?("Browser tools", href: "/bookmarklet")
      click_on("Browser tools")

      assert page.has_selector?("ol")
      assert page.has_link?("Maslow need")
      assert find_link("Maslow need")["href"].include?("https://maslow.publishing.service.gov.uk/needs/")
    end
  end
end
