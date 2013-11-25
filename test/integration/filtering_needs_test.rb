require_relative '../integration_test_helper'

class FilteringNeedsTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
  end

  context "filtering the list of needs" do
    setup do
      need_api_has_organisations(
        "department-for-education" => "Department for Education",
        "hm-passport-office" => "HM Passport Office",
        "home-office" => "Home Office"
      )

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

      need_api_has_needs_for_organisation("home-office", [
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

    should "display a subset of the needs" do
      visit "/needs"

      assert page.has_text?("10001")
      assert page.has_text?("Apply for a primary school place")
      assert page.has_text?("Department for Education")

      assert page.has_text?("10002")
      assert page.has_text?("Find out about becoming a British citizen")
      assert page.has_text?("Home Office")
      assert page.has_text?("HM Passport Office")

      select("Home Office", from: "Filter needs by organisation:")
      click_on_first("Filter")

      assert page.has_text?("Find out about becoming a British citizen")
      assert page.has_no_text?("Apply for a primary school place")
    end
  end
end
