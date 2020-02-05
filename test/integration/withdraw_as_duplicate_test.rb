# encoding: UTF-8

require_relative "../integration_test_helper"

class WithdrawAsDuplicateTest < ActionDispatch::IntegrationTest
  include NeedHelper

  setup do
    login_as_stub_editor

    content_item = create(:need_content_item)
    duplicate_content_item = create(:need_content_item, publication_state: "published")
    stub_publishing_api_has_linkables([], document_type: "organisation")
    publishing_api_has_content(
      [content_item, duplicate_content_item],
      Need.default_options,
    )
    publishing_api_has_content(
      [content_item, duplicate_content_item],
      Need.default_options.merge(per_page: 1e10, states: %w[published]),
    )
    publishing_api_has_item(content_item)
    publishing_api_has_item(duplicate_content_item)
    stub_publishing_api_has_links(
      content_id: content_item["content_id"],
      links: { organisations: [] },
    )
    stub_publishing_api_has_links(
      content_id: duplicate_content_item["content_id"],
      links: { organisations: [] },
    )

    publishing_api_has_linked_items(
      [],
      content_id: duplicate_content_item["content_id"],
      link_type: "meets_user_needs",
      fields: %w[title base_path document_type],
    )

    @need_content_id = content_item["content_id"]
    @need_goal = content_item["details"]["goal"]
    @duplicate_need_content_id = duplicate_content_item["content_id"]
    @duplicate_need_goal = duplicate_content_item["content_id"]
  end

  should "be able to close a need as a duplicate" do
    request = stub_publishing_api_unpublish(
      @duplicate_need_content_id,
      body: {
        type: "withdrawal",
        explanation: "This need is a duplicate of: [embed:link:#{@need_content_id}]",
      },
    )
    visit "/needs/#{@duplicate_need_content_id}/actions"

    click_on "Withdraw as a Duplicate"

    assert_requested request
  end

  should "show an error message if there's a problem closing the need as a duplicate" do
    Need.any_instance.expects(:unpublish).returns(false)

    visit "/needs/#{@duplicate_need_content_id}/actions"

    click_on "Withdraw as a Duplicate"

    assert page.has_content?("There was a problem updating the need’s status")
  end

  context "with a withdrawn need" do
    setup do
      login_as_stub_editor

      duplicate_content_item = create(
        :need_content_item,
        publication_state: "unpublished",
        unpublishing: {
          explanation: "Foo",
        },
      )
      publishing_api_has_item(duplicate_content_item)

      stub_publishing_api_has_links(
        content_id: duplicate_content_item["content_id"],
        links: { organisations: [] },
      )
      publishing_api_has_linked_items(
        [],
        content_id: duplicate_content_item["content_id"],
        link_type: "meets_user_needs",
        fields: %w[title base_path document_type],
      )

      @content_id = duplicate_content_item["content_id"]
    end

    should "not be able to edit" do
      visit "/needs/#{@content_id}/edit"

      assert page.has_content?("Closed needs cannot be edited")
      assert page.has_no_link?("Edit")
    end

    should "not be able to edit from the history page" do
      visit "/needs/#{@content_id}/revisions"

      assert page.has_no_link?("Edit")
    end
  end

  should "be able to add a new need from this page" do
    visit "/needs/#{@duplicate_need_content_id}/actions"

    within "#workflow" do
      assert page.has_link?("Add a new need", href: "/needs/new")
    end
  end
end
