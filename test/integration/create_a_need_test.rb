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
    need_api_has_needs([])
  end

  context "Creating a need" do
    should "be able to access 'Add a Need' page" do
      visit('/needs')
      click_on('Add a new need')

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

      assert page.has_text?("Do you think GOV.UK currently has functionality that meets this need?")
      assert page.has_text?("Do you have any other qualitative or quantitative data that supports this need?")
      assert page.has_text?("Contacts in a month in relation to this need")
      assert page.has_text?("Page views for your site in a month")
      assert page.has_text?("Page views for the need in a month")
      assert page.has_text?("Number of searches for this need in a month")
      assert page.has_text?("What legislation underpins this need?")
    end

    should "be able to create a new Need" do
      request = stub_request(:post, Plek.current.find('need-api')+'/needs').with(
        :body => {
          "role" => "User",
          "goal" => "find my local register office",
          "benefit" => "I can find records of birth, marriage or death",
          "organisation_ids" => ["ministry-of-justice"],
          "impact" => "Noticed by the average member of the public",
          "justifications" => ["it's something only government does",
                               "it's straightforward advice that helps people to comply with their statutory obligations"],
          "met_when" => ["Can download a birth certificate."],
          "currently_met" => false,
          "other_evidence" => "Free text evidence with lots more evidence",
          "legislation" => ["http://www.legislation.gov.uk/stuff","http://www.legislation.gov.uk/stuff"],
          "monthly_user_contacts" => 10000,
          "monthly_site_views" => 1000000,
          "monthly_need_views" => 1000,
          "monthly_searches" => 2000
      }.to_json)

      visit('/needs')
      click_on('Add a new need')

      fill_in("As a", with: "User")
      fill_in("I want to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")
      select("Ministry of Justice", from: "Organisations")
      check("it's straightforward advice that helps people to comply with their statutory obligations")
      check("it's something only government does")
      choose("Noticed by the average member of the public")
      choose("No")
      fill_in("Do you have any other qualitative or quantitative data that supports this need?", with: "Free text evidence with lots more evidence")
      fill_in("Contacts in a month in relation to this need", with: 10000)
      fill_in("Page views for your site in a month", with: 1000000)
      fill_in("Page views for the need in a month", with: 1000)
      fill_in("Number of searches for this need in a month", with: 2000)
      fill_in("What legislation underpins this need?", with: "http://www.legislation.gov.uk/stuff\nhttp://www.legislation.gov.uk/stuff")

      fill_in("Need is likely to be met when", with: "Can download a birth certificate.")

      click_on("Create Need")
      assert_requested request
      assert page.has_text?("Need created.")
    end

    should "retain previous values when the need content is incomplete" do
      visit('/needs')
      click_on('Add a new need')

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
      click_on('Add a new need')

      click_on("Create Need")

      assert_equal("", find_field("Need is likely to be met when").value)
    end
  end

end
