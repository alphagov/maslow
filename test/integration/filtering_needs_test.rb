require_relative '../integration_test_helper'

class FilteringNeedsTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user
  end

  context "filtering the list of needs" do
    setup do
      need_api_has_organisations(
        "department-for-education" => { "name" => "Department for Education",
                                        "abbreviation" => "DfE"
                                      },
        "hm-passport-office" => "HM Passport Office",
        "home-office" => "Home Office"
      )

      @needs = [
        minimal_example_need(
          "id" => "10001",
          "goal" => "apply for a primary school place",
          "organisation_ids" => ["department-for-education"],
          "organisations" => [
            {
              "id" => "department-for-education",
              "name" => "Department for Education",
              "abbreviation" => "DfE"
            }
          ],
        ),
        minimal_example_need(
          "id" => "10002",
          "goal" => "apply for a secondary school place",
          "organisation_ids" => ["department-for-education"],
          "organisations" => [
            {
              "id" => "department-for-education",
              "name" => "Department for Education",
              "abbreviation" => "DfE"
            }
          ],
        ),
        minimal_example_need(
          "id" => "10003",
          "goal" => "find out about becoming a British citizen primary",
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
        )
      ]

      need_api_has_needs(@needs)
      need_api_has_needs_for_organisation("department-for-education", [@needs[0], @needs[1]])
      need_api_has_needs_for_search("primary", [@needs[0], @needs[3]])
      need_api_has_needs_for_search_and_filter("primary", "department-for-education", [@needs[0]])
    end

    should "display needs related to an organisation" do
      visit "/needs"

      assert page.has_text?("10001")
      assert page.has_text?("Apply for a primary school place")
      assert page.has_text?("Department for Education [DfE]")

      assert page.has_text?("10003")
      assert page.has_text?("Find out about becoming a British citizen")
      assert page.has_text?("Home Office")
      assert page.has_text?("HM Passport Office")

      select("Department for Education [DfE]", from: "Filter needs by organisation:")
      click_on_first_button("Filter")

      within "#needs" do
        assert page.has_text?("Department for Education")
        assert page.has_text?("Apply for a primary school place")
        assert page.has_no_text?("Find out about becoming a British citizen")
      end
    end

    should "display needs related to an organisation and filtered by text" do
      visit "/needs"

      select("Department for Education [DfE]", from: "Filter needs by organisation:")
      click_on_first_button("Filter")

      within "#needs" do
        assert page.has_text?("Apply for a primary school place")
        assert page.has_text?("Apply for a secondary school place")
        refute page.has_text?("find out about becoming a British citizen primary")
      end

      fill_in("Search needs", with: "primary")
      click_on("Search")

      within "#needs" do
        assert page.has_text?("Apply for a primary school place")
        refute page.has_text?("Apply for a secondary school place")
        refute page.has_text?("find out about becoming a British citizen primary")
      end
    end

    context "filtering from showing a need" do
      setup do
        need_api_has_need(@needs[0])
        content_api_has_artefacts_for_need_id("10001", [])
      end

      should "filter when clicking on an organisation while showing a need" do
        visit "/needs"
        click_on "10001"

        within ".need-organisations" do
          assert page.has_link?("Department for Education",
                                href: needs_url(organisation_id: "department-for-education"))
        end

        click_on "Department for Education"

        within "#needs" do
          assert page.has_text?("Department for Education")
          assert page.has_text?("Apply for a primary school place")
          assert page.has_no_link?("Department for Education")
        end
      end
    end
  end
end
