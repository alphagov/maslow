require_relative '../integration_test_helper'

class FeedbackLinkTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user
    need_api_has_organisations([])
    need_api_has_needs([])
  end

  context "on the need list" do
    should "show a feedback link if the address is set" do
      Maslow::Application.config.stubs(:feedback_address).returns("foo@example.com")
      visit "/needs"
      assert page.has_link?("Send feedback", href: "mailto:foo@example.com")
    end

    should "not show a feedback link if the address is not set" do
      Maslow::Application.config.stubs(:feedback_address).returns(nil)
      visit "/needs"
      refute page.has_link?("Send feedback")
    end
  end
end
