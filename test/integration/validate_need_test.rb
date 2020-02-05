# encoding: UTF-8

require_relative "../integration_test_helper"

class ValidateNeedTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_admin
  end

  context "marking a need as valid" do
    setup do
      @content_item = create(:need_content_item)

      stub_publishing_api_has_item(@content_item)
      stub_publishing_api_has_linkables([], document_type: "organisation")
      stub_publishing_api_has_links(
        content_id: @content_item["content_id"],
        links: {
          organisations: [],
        },
      )
      publishing_api_has_linked_items(
        [],
        content_id: @content_item["content_id"],
        link_type: "meets_user_needs",
        fields: %w[title base_path document_type],
      )
    end

    should "update the Publishing API" do
      request = stub_publishing_api_publish(
        @content_item["content_id"],
        update_type: "major",
      )

      visit "/needs/#{@content_item['content_id']}/actions"
      click_on "Validate"

      assert_requested request
    end
  end
end
