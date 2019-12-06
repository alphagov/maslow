require_relative "../integration_test_helper"

class FilteringNeedsTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user
  end

  context "filtering the list of needs" do
    setup do
      @needs = create_list(:need_content_item, 3)

      [
        "apply for a primary school place",
        "apply for a secondary school place",
        "find out about becoming a British citizen",
      ].zip(@needs).each { |goal, x| x["details"]["goal"] = goal }

      @needs.each { |need| publishing_api_has_item(need) }

      publishing_api_has_linked_items(
        [
          {
            title: "Linked item title",
            base_path: "linked_foo",
            document_type: "guide",
          },
        ],
        content_id: @needs[0]["content_id"],
        link_type: "meets_user_needs",
        fields: %w[title base_path document_type],
      )

      @department_of_education = SecureRandom.uuid
      @home_office = SecureRandom.uuid
      @hm_passport_office = SecureRandom.uuid
      publishing_api_has_linkables(
        [
          {
            content_id: @department_of_education,
            title: "Department for Education",
          },
          {
            content_id: @home_office,
            title: "Home Office",
          },
          {
            content_id: @hm_passport_office,
            title: "HM Passport Office",
          },
        ], document_type: "organisation"
      )

      publishing_api_has_links(
        content_id: @needs[0]["content_id"],
        links: {
          organisations: [@department_of_education],
        },
      )
      publishing_api_has_links(
        content_id: @needs[1]["content_id"],
        links: {
          organisations: [@department_of_education],
        },
      )
      publishing_api_has_links(
        content_id: @needs[2]["content_id"],
        links: {},
      )

      publishing_api_has_content(
        @needs,
        Need.default_options.merge(
          per_page: 50,
        ),
      )

      needs_linked_to_education = @needs[0..1]

      publishing_api_has_content(
        @needs.select { |x| x["details"]["goal"].include? "primary" },
        Need.default_options.merge(
          per_page: 50,
          q: "primary",
        ),
      )

      publishing_api_has_content(
        needs_linked_to_education,
        Need.default_options.merge(
          per_page: 50,
          link_organisations: @department_of_education,
        ),
      )

      publishing_api_has_content(
        needs_linked_to_education.select { |x| x["details"]["goal"].include? "primary" },
        Need.default_options.merge(
          per_page: 50,
          q: "primary",
          link_organisations: @department_of_education,
        ),
      )
    end

    should "display needs related to an organisation" do
      visit "/needs"

      assert page.has_text?("Apply for a primary school place")
      assert page.has_text?("Department for Education")

      assert page.has_text?("Find out about becoming a British citizen")
      assert page.has_text?("Home Office")
      assert page.has_text?("HM Passport Office")

      select("Department for Education", from: "Filter needs by organisation:")
      click_on_first_button("Filter")

      within "#needs" do
        assert page.has_text?("Department for Education")
        assert page.has_text?("Apply for a primary school place")
        assert page.has_no_text?("Find out about becoming a British citizen")
      end
    end

    should "display needs related to an organisation and filtered by text" do
      visit "/needs"
      select("Department for Education", from: "Filter needs by organisation:")
      click_on_first_button("Filter")

      within "#needs" do
        assert page.has_text?("Apply for a primary school place")
        assert page.has_text?("Apply for a secondary school place")
        assert_not page.has_text?("find out about becoming a British citizen")
      end

      fill_in("Search needs", with: "primary")
      click_on("Search")

      within "#needs" do
        assert page.has_text?("Apply for a primary school place")
        assert_not page.has_text?("Apply for a secondary school place")
        assert_not page.has_text?("find out about becoming a British citizen")
      end
    end

    context "filtering from showing a need" do
      should "filter when clicking on an organisation while showing a need" do
        visit "/needs"
        click_on "Apply for a primary school place"

        within ".need-organisations" do
          assert page.has_link?(
            "Department for Education",
            href: needs_url(organisation_id: @department_of_education),
          )
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
