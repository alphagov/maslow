require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'

class BrowsingNeedsTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as_stub_user
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
          "justifications" => [
            "it's something only government does",
            "the government is legally obliged to provide it"
          ],
          "impact" => "Has serious consequences for the day-to-day lives of your users",
          "met_when" => [
            "The user finds information about the citizenship test and the next steps"
          ]
        }
      ])
    end

    should "display a table of all the needs" do
      visit "/needs"

      assert page.has_content?("All needs")
      assert page.has_link?("Add a new need")

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
      end
    end
  end
end
