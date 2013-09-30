require_relative '../integration_test_helper'

class CreateANeedTest < ActionDispatch::IntegrationTest

  setup do
    login_as(stub_user)
  end

  context "Creating a need" do
    should "be able to access 'Add a Need' page" do
      visit('/needs')
      click_on("Add a Need")

      assert page.has_field?("As a")
      assert page.has_field?("I want to")
      assert page.has_field?("So that")
      assert page.has_field?("Organisations")
      assert page.has_text?("Why is this needed?")
      assert page.has_unchecked_field?("legislation")
      assert page.has_unchecked_field?("obligation")
      assert page.has_unchecked_field?("other")
      assert page.has_field?("Evidence")
    end
  end

end
