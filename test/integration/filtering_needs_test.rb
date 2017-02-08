require_relative '../integration_test_helper'

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
        "find out about becoming a British citizen primary"
      ].zip(@needs).each { |goal, x| x["details"]["goal"] = goal }

      publishing_api_has_content(
        @needs,
        Need.default_options.merge(
          per_page: 50
        )
      )
      publishing_api_has_linkables([], document_type: "organisation")
      @needs.each do |need|
        publishing_api_has_links(content_id: need["content_id"], links: {})
      end

      publishing_api_has_content(
        @needs.select { |x| x["details"]["goal"].include? "primary" },
        Need.default_options.merge(
          per_page: 50,
          q: "primary"
        )
      )
    end

    should "display needs related to an organisation and filtered by text" do
      visit "/needs"

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
  end
end
