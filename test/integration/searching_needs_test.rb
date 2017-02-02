require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'

class SearchingNeedsTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user
  end

  context "filtering the list of needs" do
    setup do
      need_api_has_needs([
        {
          "id" => "10001",
          "goal" => "apply for a primary school place",
          "organisation_ids" => ["department-for-education"],
          "organisations" => [
            {
              "id" => "department-for-education",
              "name" => "Department for Education",
            }
          ],
          "status" => {
            "description" => "proposed",
          },
        },
        {
          "id" => "10002",
          "goal" => "find out about becoming a British citizen",
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
          "status" => {
            "description" => "proposed",
          },
        }
      ])

      need_api_has_needs_for_search("citizenship", [
        {
          "id" => "10002",
          "goal" => "find out about becoming a British citizen",
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
          "status" => {
            "description" => "proposed",
          },
        }
      ])
    end

    should "display a list of search results" do
      visit "/needs"

      assert page.has_text?("10001")
      assert page.has_text?("Apply for a primary school place")
      assert page.has_text?("Department for Education")

      assert page.has_text?("10002")
      assert page.has_text?("Find out about becoming a British citizen")
      assert page.has_text?("Home Office")
      assert page.has_text?("HM Passport Office")

      fill_in("Search needs:", with: "citizenship")
      click_on_first_button("Search")

      assert page.has_text?("Find out about becoming a British citizen")
      assert page.has_no_text?("Apply for a primary school place")
      assert_equal("citizenship", find_field("Search needs:").value)
    end
  end
end
