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
      assert page.has_text?("Organisations")
      assert page.has_text?("Why is this needed?")
      assert page.has_unchecked_field?("legislation")
      assert page.has_unchecked_field?("obligation")
      assert page.has_unchecked_field?("other")
      assert page.has_text?("What is the impact of GOV.UK not doing this?")
      assert page.has_unchecked_field?("Endangers the health of individuals")
      assert page.has_unchecked_field?("Has serious consequences for the day-to-day lives of your users")
      assert page.has_unchecked_field?("Annoys the majority of your users. May incur fines")
      assert page.has_unchecked_field?("Noticed by the average member of the public")
      assert page.has_unchecked_field?("Noticed by an expert audience")
      assert page.has_unchecked_field?("No impact")
      assert page.has_text?("Need is likely to be met when")
    end

    should "be able to create a new Need" do
      stub_request(:post, Plek.current.find('need-api')+'/needs')

      visit('/needs')
      click_on('Add a Need')

      fill_in("As a", with: "User")
      fill_in("I want to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")
      select("Ministry of Justice", from: "Organisations")
      check("legislation")
      check("obligation")
      choose("Noticed by the average member of the public")
      fill_in("Need is likely to be met when", with: "Can download a birth certificate.")

      click_on("Create Need")
    end

    should "retain previous values when the need content is incomplete" do
      visit('/needs')
      click_on('Add a Need')

      fill_in("As a", with: "User")
      check("legislation")
      fill_in("Need is likely to be met when", with: "Can download a birth certificate.\nOther criteria")

      click_on("Create Need")

      assert_equal("Can download a birth certificate.\nOther criteria",
                   find_field("Need is likely to be met when").value)
    end

    should "not have any fields filled in when submitting a blank form" do
      visit('/needs')
      click_on('Add a Need')

      click_on("Create Need")

      assert_equal("", find_field("Need is likely to be met when").value)
    end
  end

end
