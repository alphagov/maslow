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
      Need::JUSTIFICATIONS.each do |just|
        assert page.has_unchecked_field?(just), "Missing justification: #{just}"
      end

      assert page.has_text?("What is the impact of GOV.UK not doing this?")
      Need::IMPACT.each do |impact|
        assert page.has_unchecked_field?(impact), "Missing impact: #{impact}"
      end

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
          "justifications" => ["It's something only government does",
                               "It's straightforward advice that helps people to comply with their statutory obligations"],
          "met_when" => ["Can download a birth certificate."],
          "currently_met" => false,
          "other_evidence" => "Free text evidence with lots more evidence",
          "legislation" => "http://www.legislation.gov.uk/stuff\nhttp://www.legislation.gov.uk/stuff",
          "monthly_user_contacts" => 10000,
          "monthly_site_views" => 1000000,
          "monthly_need_views" => 1000,
          "monthly_searches" => 2000,
          "author" => {
            "name" => stub_user.name,
            "email" => stub_user.email,
            "uid" => stub_user.uid
          }
      }.to_json)

      visit('/needs')
      click_on('Add a new need')

      fill_in("As a", with: "User")
      fill_in("I want to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")
      select("Ministry of Justice", from: "Organisations")
      check("It's straightforward advice that helps people to comply with their statutory obligations")
      check("It's something only government does")
      choose("Noticed by the average member of the public")
      choose("No")
      fill_in("Do you have any other qualitative or quantitative data that supports this need?", with: "Free text evidence with lots more evidence")
      fill_in("Contacts in a month in relation to this need", with: 10000)
      fill_in("Page views for your site in a month", with: 1000000)
      fill_in("Page views for the need in a month", with: 1000)
      fill_in("Number of searches for this need in a month", with: 2000)
      fill_in("What legislation underpins this need?", with: "http://www.legislation.gov.uk/stuff\nhttp://www.legislation.gov.uk/stuff")
      fill_in("Need is likely to be met when", with: "Can download a birth certificate.")

      click_on_first("Create Need")
      assert_requested request
      assert page.has_text?("Need created.")
    end

    should "retain previous values when the need content is incomplete" do
      visit('/needs')
      click_on('Add a new need')

      fill_in("As a", with: "User")
      check("It's something only government does")
      fill_in("Need is likely to be met when", with: "Can download a birth certificate.\nOther criteria")

      click_on_first("Create Need")

      assert page.has_text?("Please fill in the required fields.")
      assert_equal("Can download a birth certificate.\nOther criteria",
                   find_field("Need is likely to be met when").value)
    end

    should "not have any fields filled in when submitting a blank form" do
      visit('/needs')
      click_on('Add a new need')

      click_on_first("Create Need")

      assert_equal("", find_field("Need is likely to be met when").value)
    end

    should "handle 422 errors from the Need API" do
      request = stub_request(:post, Plek.current.find('need-api')+'/needs').with(
        :body => {
          "role" => "User",
          "goal" => "find my local register office",
          "benefit" => "I can find records of birth, marriage or death",
          "author" => {
            "name" => stub_user.name,
            "email" => stub_user.email,
            "uid" => stub_user.uid
          }
      }.to_json).to_return(status: 422, body: { _response_info: { status: "invalid_attributes" }, errors: [ "error 1", "error 2"] }.to_json)

      visit('/needs')
      click_on('Add a new need')

      fill_in("As a", with: "User")
      fill_in("I want to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")

      click_on_first("Create Need")

      assert page.has_text?("There was a problem saving your need.")
    end
  end

end
