require_relative '../integration_test_helper'

class MaslowNeedBookmarkletTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user
    need_api_has_organisations([])
    need_api_has_needs([])
  end

  context "on the navbar" do
    should "link to 'Maslow need' bookmarklet" do
      visit "/needs"
      assert page.has_link?("Maslow browser tools", href: "/maslow-need-bookmarklet")
      click_on("Maslow browser tools")

      assert page.has_selector?("ol")
      assert page.has_link?("Maslow need")
      assert find_link("Maslow need")["href"].include?("https://maslow.production.alphagov.co.uk/needs/")
    end
  end
end
