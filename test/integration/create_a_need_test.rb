require_relative '../integration_test_helper'

class CreateANeedTest < ActionDispatch::IntegrationTest

  setup do
    login_as(stub_user)
  end

  context "Creating a need" do
    should "be able to access 'Add a Need' page" do
      visit('/needs')
      click_on('Add a Need')

      assert page.has_field?("As a")
      assert page.has_field?("I want to")
      assert page.has_field?("So that")
      assert page.has_field?("Organisations")
      assert page.has_text?("Why is this needed?")
      assert page.has_unchecked_field?("legislation")
      assert page.has_unchecked_field?("obligation")
      assert page.has_unchecked_field?("other")
      assert page.has_text?("What is the impact of GOV.UK not doing this?")
      assert page.has_unchecked_field?("Ben's impact #1")
      assert page.has_unchecked_field?("Ben's impact #2")
      assert page.has_unchecked_field?("Ben's impact #3")
      assert page.has_field?("Evidence")
    end

    should "be able to create a new Need" do
      visit('/needs')
      click_on('Add a Need')

      fill_in("As a", with: "User")
      fill_in("I want to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")
      fill_in("Organisations", with: "Department of Justice")
      check("legislation")
      check("obligation")
      choose("Ben's impact #1")
      fill_in("Evidence", with: "web links, legislation references")

      click_on("Create Need")
    end
  end

end
