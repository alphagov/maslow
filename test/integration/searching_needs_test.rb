require_relative "../integration_test_helper"

class SearchingNeedsTest < ActionDispatch::IntegrationTest
  include NeedHelper

  setup do
    login_as_stub_user
  end

  context "filtering the list of needs" do
    setup do
      @content = [
        create(:need_content_item),
        create(
          :need_content_item,
          title: "Foo",
          details: {
            goal: "Foo goal",
          },
        ),
      ]

      publishing_api_has_content([@content[1]], Need.default_options.merge(q: "Foo"))
      publishing_api_has_content(@content, Need.default_options)

      stub_publishing_api_has_linkables([], document_type: "organisation")

      get_links_url = %r{\A#{Plek.find('publishing-api')}/v2/links}
      stub_request(:get, get_links_url).to_return(
        body: { links: { organisations: [] } }.to_json,
      )
    end

    should "display a list of search results" do
      visit "/needs"

      @content.each do |need_content|
        assert page.has_text?(format_need_goal(need_content["details"]["goal"]))
      end

      fill_in("Search needs:", with: "Foo")
      click_on_first_button("Search")

      assert page.has_text?(format_need_goal(@content[1]["details"]["goal"]))
      assert page.has_no_text?(format_need_goal(@content[0]["details"]["goal"]))
      assert_equal("Foo", find_field("Search needs:").value)
    end
  end
end
