# encoding: UTF-8
require_relative '../integration_test_helper'

class BrowsingNeedsTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user
    need_api_has_organisations([])
  end

  context "viewing the list of needs" do
    setup do
      need_api_has_needs([
        {
          "id" => "10001",
          "role" => "parent",
          "goal" => "apply for a primary school place",
          "benefit" => "my child can start school",
          "organisation_ids" => ["department-for-education"],
          "organisations" => [
            {
              "id" => "department-for-education",
              "name" => "Department for Education",
            }
          ],
          "applies_to_all_organisations" => false,
          "justifications" => [
            "it's something only government does",
            "the government is legally obliged to provide it"
          ],
          "impact" => "Has serious consequences for the day-to-day lives of your users",
          "met_when" => [
            "The user applies for a school place"
          ]
        },
        {
          "id" => "10002",
          "role" => "user",
          "goal" => "find out about becoming a British citizen",
          "benefit" => "i can take the correct steps to apply for citizenship",
          "organisation_ids" => ["home-office", "hm-passport-office"],
          "organisations" => [
            {
              "id" => "home-office",
              "name" => "Home Office",
            },
            {
              "id" => "hm-passport-office",
              "name" => "HM Passport Office",
            }
          ],
          "applies_to_all_organisations" => false,
          "justifications" => [
            "it's something only government does",
            "the government is legally obliged to provide it"
          ],
          "impact" => "Has serious consequences for the day-to-day lives of your users",
          "met_when" => [
            "The user finds information about the citizenship test and the next steps"
          ]
        },
        {
          "id" => "10003",
          "role" => "user",
          "goal" => "find out about government policy",
          "benefit" => "i can keep up to date with what's happening in government",
          "organisation_ids" => [],
          "organisations" => [],
          "applies_to_all_organisations" => true,
          "justifications" => [
            "it's something only government does",
            "the government is legally obliged to provide it"
          ],
          "impact" => "Has serious consequences for the day-to-day lives of your users",
          "met_when" => []
        }
      ])
    end

    should "display a table of all the needs" do
      visit "/needs"

      assert page.has_content?("All needs")
      within "#workflow" do
        assert page.has_link?("Add a new need")
      end

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
          assert page.has_content?("Applies to all organisations")
        end
      end
    end
  end

  should "be able to navigate between pages of results" do
    page_one = File.read( Rails.root.join("test", "fixtures", "needs", "index_page_1.json") )
    need_api_has_raw_response_for_page(page_one, nil)

    page_two = File.read( Rails.root.join("test", "fixtures", "needs", "index_page_2.json") )
    need_api_has_raw_response_for_page(page_two, "2")

    page_three = File.read( Rails.root.join("test", "fixtures", "needs", "index_page_3.json") )
    need_api_has_raw_response_for_page(page_three, "3")

    visit "/needs"

    # assert the content on page 1
    within "table#needs" do
      assert page.has_content?("Tax my vehicle")
      assert page.has_content?("Complain about an advert for a medical product")
      assert page.has_content?("Advertise my product")
    end

    within ".pagination" do
      assert page.has_content?("Page 1 of 3")
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
      assert page.has_content?("Page 2 of 3")
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
      assert page.has_content?("Page 3 of 3")
      assert page.has_selector?("li.active", text: "3")

      assert page.has_link?("1", href: "/needs")
      assert page.has_link?("2", href: "/needs?page=2")

      assert page.has_no_link?("Next ›")
      assert page.has_link?("‹ Prev", href: "/needs?page=2")
    end
  end
end
