require_relative '../integration_test_helper'

class ListNeedsTest < ActionDispatch::IntegrationTest
  setup do
    login_as(stub_user)
  end

  context "Viewing needs" do
    should "see a list of needs already submitted through the application" do
      visit('/needs')
      assert page.has_text?("Need 1")
      assert page.has_text?("Need 2")
    end
  end
end
