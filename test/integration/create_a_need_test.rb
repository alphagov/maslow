require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'

class CreateANeedTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as(stub_user)
    need_api_has_organisations(
      "committee-on-climate-change" => "Committee on Climate Change",
      "competition-commission" => "Competition Commission",
      "ministry-of-justice" => "Ministry of Justice"
    )
  end

  context "Creating a need" do
    should "be able to access 'Add a Need' page" do
      visit('/needs')
      click_on('Add a Need')

      assert page.has_field?("As a")
      assert page.has_field?("I want to")
      assert page.has_field?("So that")
      assert page.has_text?("Organisations")
      assert page.has_text?("Competition Commission")
      assert page.has_text?("Committee on Climate Change")
      assert page.has_text?("Why is this needed?")
      assert page.has_unchecked_field?("it's something only government does")
      assert page.has_unchecked_field?("the government is legally obliged to provide it")
      assert page.has_unchecked_field?("it's inherent to a person's or an organisation's rights and obligations")
      assert page.has_unchecked_field?("it's something that people can do or it's something people need to know before they can do something that's regulated by/related to government")
      assert page.has_unchecked_field?("there is clear demand for it from users")
      assert page.has_unchecked_field?("it's something the government provides/does/pays for")
      assert page.has_unchecked_field?("it's straightforward advice that helps people to comply with their statutory obligations")
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
      check("it's straightforward advice that helps people to comply with their statutory obligations")
      check("it's something only government does")
      choose("Noticed by the average member of the public")
      fill_in("Need is likely to be met when", with: "Can download a birth certificate.")

      click_on("Create Need")
      assert page.has_text?("Need created.")
    end

    should "retain previous values when the need content is incomplete" do
      visit('/needs')
      click_on('Add a Need')

      fill_in("As a", with: "User")
      check("it's something only government does")
      fill_in("Need is likely to be met when", with: "Can download a birth certificate.\nOther criteria")

      click_on("Create Need")

      assert page.has_text?("Please fill in the required fields.")
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
