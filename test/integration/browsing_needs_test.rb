# encoding: UTF-8
require_relative '../integration_test_helper'
require 'gds_api/test_helpers/organisations'
require 'gds_api/test_helpers/publishing_api_v2'

class BrowsingNeedsTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::PublishingApiV2

  setup do
    login_as_stub_user
    organisations_api_has_organisations([])
  end

  context "viewing the list of needs" do
    should "display a table of all the needs" do
      publishing_api_has_content(
        FactoryGirl.create_list(:need_content_item, 3),
        document_type: "need",
        fields: [
          "content_id",
          "details",
          "need_ids",
          "publication_state",
        ],
        locale: "en",
        order: "-public_updated_at",
        per_page: 50,
        publishing_app: "need-api"
      )

      visit "/needs"

      assert page.has_content?("All needs")

      within "table#needs" do
        within "tbody tr:nth-of-type(1)" do
          assert page.has_content?("10001")
          assert page.has_content?("Apply for a primary school place")
          assert page.has_content?("Department for Education")
        end

        within "tbody tr:nth-of-type(2)" do
          assert page.has_content?("10002")
          assert page.has_content?("Find out about becoming a British citizen")
          assert page.has_content?("Home Office, HM Passport Office")
        end

        within "tbody tr:nth-of-type(3)" do
          assert page.has_content?("10003")
          assert page.has_content?("Find out about government policy")
          assert page.has_content?("Not valid, Duplicate")
          assert page.has_content?("Applies to all organisations")
        end
      end
    end
  end

  should "be able to navigate between pages of results" do
    publishing_api_has_content(
      FactoryGirl.create(:need_content_item),
      document_type: "need",
      fields: [
        "content_id",
        "details",
        "need_ids",
        "publication_state",
      ],
      locale: "en",
      order: "-public_updated_at",
      per_page: 50,
      publishing_app: "need-api"
    )

    visit "/needs"

    # assert the content on page 1
    within "table#needs" do
      assert page.has_content?("Tax my vehicle")
      assert page.has_content?("Complain about an advert for a medical product")
      assert page.has_content?("Advertise my product")
    end

    within ".pagination" do
      assert page.has_selector?("li.active", text: "1")

      assert page.has_link?("2", href: "/needs?page=2")
      assert page.has_link?("3", href: "/needs?page=3")

      assert page.has_no_link?("‹ Prev")
      assert page.has_link?("Next ›", href: "/needs?page=2")

      click_on "Next ›"
    end

    # assert the content on page 2
    within "table#needs" do
      assert page.has_content?("Access employee deal data, terms and condition and the competency framework")
      assert page.has_content?("Understand panel counsel appointments, rates and work opportunities")
      assert page.has_content?("Buy or claim an asset of a dissolved company")
    end

    within ".pagination" do
      assert page.has_selector?("li.active", text: "2")

      assert page.has_link?("1", href: "/needs")
      assert page.has_link?("3", href: "/needs?page=3")

      assert page.has_link?("‹ Prev", href: "/needs")
      assert page.has_link?("Next ›", href: "/needs?page=3")

      click_on "Next ›"
    end

    # assert the content on page 3
    within "table#needs" do
      assert page.has_content?("Find information about the Ogden Tables and look-up information in those tables")
      assert page.has_content?("Know about Fair Deal policy, Broad Comparability, Bulk Transfers, Communicating to Staff, Bid Support etc")
      assert page.has_content?("Know what services they provide")
    end

    within ".pagination" do
      assert page.has_selector?("li.active", text: "3")

      assert page.has_link?("1", href: "/needs")
      assert page.has_link?("2", href: "/needs?page=2")

      assert page.has_no_link?("Next ›")
      assert page.has_link?("‹ Prev", href: "/needs?page=2")
    end
  end
end
