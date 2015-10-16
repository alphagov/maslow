# encoding: UTF-8
require_relative '../integration_test_helper'

class DecideOnNeedTest < ActionDispatch::IntegrationTest
  def need_hash
    {
      "id" => "100001",
      "role" => "parent",
      "goal" => "apply for a primary school place",
      "benefit" => "my child can start school",
      "met_when" => %w(win awesome more),
      "organisations" => [],
      "legislation" => "Blank Fields Act 2013",
      "revisions" => [],
      "applies_to_all_organisations" => false
    }
  end

  setup do
    login_as_stub_admin
    need_api_has_organisations(
      "committee-on-climate-change" => "Committee on Climate Change",
      "competition-commission" => "Competition Commission",
      "ministry-of-justice" => "Ministry of Justice"
    )
  end

  context "marking a need as not valid" do
    setup do
      @need = need_hash.merge(
        "status" => {
          "description" => "proposed",
        },
      )
      need_api_has_needs([@need]) # For need list
      content_api_has_artefacts_for_need_id("100001", [])

      @api_url = Plek.current.find('need-api') + '/needs/100001'
    end

    should "update the Need API" do
      need_api_has_need(@need) # For individual need

      request = stub_request(:put, @api_url).with(body: hash_including({
        "status" => {
          "description" => "not valid",
          "reasons" => [
            "it has typos or acronyms that aren’t defined",
            "it’s incomplete or imprecise",
            "the user needs to be defined more precisely",
          ],
        },
      }))

      visit "/needs"
      click_on "100001"
      click_on "Actions"

      # There are two 'Decide on need' buttons
      # The second is a confirmation modal drop down when JavaScript is on
      # The first is an action initiator in the header
      within "#workflow #decide-on-need" do
        click_on "Decide on need"
      end

      within ".non-js-form" do
        # This is a confirmation on a separate page when JavaScript is off
        choose "not valid - the need is badly formed, lacks detail, or is out of proposition"
        check "it’s incomplete or imprecise"
        check "it has typos or acronyms that aren’t defined"
        fill_in "Any other reason why the need is invalid (optional)", with: "the user needs to be defined more precisely"
        click_on "Update the status"
      end

      assert_requested request
    end

    should "show an error message if there's a problem updating the status" do
      need_api_has_need(@need) # For individual need
      request = stub_request(:put, @api_url).to_return(status: 422)

      visit "/needs"
      click_on "100001"
      click_on "Actions"

      within "#workflow #decide-on-need" do
        click_on "Decide on need"
      end

      within ".non-js-form" do
        choose "not valid - the need is badly formed, lacks detail, or is out of proposition"
        fill_in "Any other reason why the need is invalid (optional)", with: "foo"
        click_on "Update the status"
      end

      assert page.has_content?("We had a problem updating the need’s status")
    end

    should "show an error message if there is no reason why the need is not valid" do
      need_api_has_need(@need) # For individual need

      visit "/needs"
      click_on "100001"
      click_on "Actions"

      within "#workflow #decide-on-need" do
        click_on "Decide on need"
      end

      within ".non-js-form" do
        choose "not valid - the need is badly formed, lacks detail, or is out of proposition"
        click_on "Update the status"
      end

      assert page.has_content?("A reason is required to mark a need as not valid")
    end
  end

  context "marking a need as valid" do
    setup do
      @need = need_hash.merge(
        "status" => {
          "description" => "proposed",
        },
      )
      need_api_has_needs([@need]) # For need list
      content_api_has_artefacts_for_need_id("100001", [])

      @api_url = Plek.current.find('need-api') + '/needs/100001'
    end

    should "update the Need API" do
      need_api_has_need(@need) # For individual need

      request = stub_request(:put, @api_url).with(body: hash_including({
        "status" => {
          "description" => "valid",
          "additional_comments" => "Really top need",
        },
      }))

      visit "/needs"
      click_on "100001"
      click_on "Actions"

      # There are two 'Decide on need' buttons
      # The second is a confirmation modal drop down when JavaScript is on
      # The first is an action initiator in the header
      within "#workflow #decide-on-need" do
        click_on "Decide on need"
      end

      within ".non-js-form" do
        # This is a confirmation on a separate page when JavaScript is off
        choose "valid - it’s good for a content designer to work with on a content plan"
        fill_in "Additional comments (optional)", with: "Really top need"
        click_on "Update the status"
      end

      assert_requested request
    end
  end

  context "marking a need as valid with conditions" do
    setup do
      @need = need_hash.merge(
        "status" => {
          "description" => "proposed",
        },
      )
      need_api_has_needs([@need]) # For need list
      content_api_has_artefacts_for_need_id("100001", [])

      @api_url = Plek.current.find('need-api') + '/needs/100001'
    end

    should "update the Need API" do
      need_api_has_need(@need) # For individual need

      request = stub_request(:put, @api_url).with(body: hash_including({
        "status" => {
          "description" => "valid with conditions",
          "validation_conditions" => "The need is fine, just abc needs to be clarified",
        },
      }))

      visit "/needs"
      click_on "100001"
      click_on "Actions"

      # There are two 'Decide on need' buttons
      # The second is a confirmation modal drop down when JavaScript is on
      # The first is an action initiator in the header
      within "#workflow #decide-on-need" do
        click_on "Decide on need"
      end

      within ".non-js-form" do
        # This is a confirmation on a separate page when JavaScript is off
        choose "valid with conditions - there are some minor questions or requests for clarity"
        fill_in "What needs to change before the need is valid?", with: "The need is fine, just abc needs to be clarified"
        click_on "Update the status"
      end

      assert_requested request
    end
  end

  context "setting a need back to proposed" do
    setup do
      @need = need_hash.merge(
        "status" => {
          "description" => "not valid",
          "reasons" => [NeedStatus::COMMON_REASONS_WHY_INVALID.first, "some reasons"]
        },
      )
      need_api_has_needs([@need]) # For need list
      content_api_has_artefacts_for_need_id("100001", [])

      @api_url = Plek.current.find('need-api') + '/needs/100001'
    end

    should "update the Need API" do
      need_api_has_need(@need) # For individual need

      request = stub_request(:put, @api_url).with(body: hash_including({
        "status" => {
          "description" => "proposed",
        },
      }))

      visit "/needs"
      click_on "100001"
      click_on "Actions"

      # There are two 'Decide on need' buttons
      # The second is a confirmation modal drop down when JavaScript is on
      # The first is an action initiator in the header
      within "#workflow #decide-on-need" do
        click_on "Decide on need"
      end

      within ".non-js-form" do
        assert has_checked_field?(NeedStatus::COMMON_REASONS_WHY_INVALID.first)
        assert has_field?("Any other reason why the need is invalid (optional)", with: "some reasons")

        # This is a confirmation on a separate page when JavaScript is off
        choose "proposed"
        click_on "Update the status"
      end

      assert_requested request
    end
  end
end
