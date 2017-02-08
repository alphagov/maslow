# encoding: UTF-8
require_relative '../integration_test_helper'

class UpdateANeedTest < ActionDispatch::IntegrationTest
  include NeedHelper

  setup do
    login_as_stub_editor
    publishing_api_has_linkables([], document_type: "organisation")
  end

  context "updating a need" do
    setup do
      @content_item = create(:need_content_item)
      publishing_api_has_content(
        [@content_item],
        Need.default_options.merge(
          per_page: 50
        )
      )
      publishing_api_has_linked_items(
        [],
        content_id: @content_item["content_id"],
        link_type: "meets_user_needs",
        fields: ["title", "base_path", "document_type"]
      )
      publishing_api_has_links(
        content_id: @content_item["content_id"],
        links: {
          organisations: []
        }
      )
      publishing_api_has_item(@content_item)
    end

    should "be able to access edit form" do
      visit('/needs')

      click_on(format_need_goal(@content_item["details"]["goal"]))
      within "#workflow" do
        click_on("Edit")
      end

      assert page.has_content?("Edit need")

      assert page.has_field?("As a")
      assert page.has_field?("I need to")
      assert page.has_field?("So that")
      # Other fields are tested in create_a_need_test.rb
    end

    should "be able to update a need" do
      test_need = Need.find(@content_item["content_id"])
      test_need.update(
        role: "grandparent",
        benefit: "my grandchild can start school",
      )
      payload = test_need.send(:publishing_api_payload)

      stub_publishing_api_put_content(@content_item["content_id"], payload)
      stub_publishing_api_patch_links(
        @content_item["content_id"],
        {
          links: { "organisations" => [] }
        }
      )

      visit('/needs')

      click_on(format_need_goal(@content_item["details"]["goal"]))
      within "#workflow" do
        assert page.has_link?("Edit", href: "/needs/#{@content_item["content_id"]}/edit")
        click_on("Edit")
      end

      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      fill_in("What legislation underpins this need?", with: "")
      within "#workflow" do
        click_on_first_button("Save")
      end

      assert_publishing_api_put_content(@content_item["content_id"], payload)
      assert page.has_text?("Need updated"), "No success message displayed"
    end

    should "be able to update the organisations for a need" do
      content_id_of_organisation_to_add = SecureRandom.uuid
      publishing_api_has_linkables([
        {
          "content_id": SecureRandom.uuid,
          "title" => "Committee on Climate Change",
        },
        {
          "content_id": content_id_of_organisation_to_add,
          "title" => "Ministry Of Justice",
        }
      ], document_type: "organisation")

      test_need = Need.find(@content_item["content_id"])
      payload = test_need.send(:publishing_api_payload)

      stub_publishing_api_put_content(@content_item["content_id"], payload)

      request = stub_publishing_api_patch_links(
        @content_item["content_id"],
        links: {
          "organisations" => [content_id_of_organisation_to_add]
        }
      )

      visit('/needs')

      click_on(format_need_goal(@content_item["details"]["goal"]))
      within "#workflow" do
        assert page.has_link?("Edit", href: "/needs/#{@content_item["content_id"]}/edit")
        click_on("Edit")
      end

      select("Ministry Of Justice", from: "Departments and agencies")
      within "#workflow" do
        click_on_first_button("Save")
      end

      assert_requested request
    end

    should "display met_when criteria on multiple lines" do
      met_when = %w(win awesome)
      @content_item["details"]["met_when"] = met_when
      publishing_api_has_item(@content_item)

      visit('/needs')
      click_on(format_need_goal(@content_item["details"]["goal"]))
      within "#workflow" do
        click_on("Edit")
      end

      within "#met-when-criteria" do
        met_when.each_with_index do |criteria, index|
          assert_equal(criteria, find_field("criteria-#{index}").value)
        end
      end
    end

    should "be able to add more met_when criteria" do
      need = Need.send(:need_from_publishing_api_payload, @content_item)
      expected_payload = need.send(:publishing_api_payload)
      expected_payload[:details]["met_when"] << "more"
      request = stub_publishing_api_put_content(
        @content_item["content_id"],
        expected_payload
      )

      stub_publishing_api_patch_links(
        @content_item["content_id"],
        {
          links: { "organisations" => [] }
        }
      )

      visit('/needs')
      click_on(format_need_goal(@content_item["details"]["goal"]))
      within "#workflow" do
        click_on("Edit")
      end

      @content_item["details"]["met_when"].each_with_index do |criteria, index|
        assert_equal(criteria, find_field("criteria-#{index}").value)
      end

      within "#met-when-criteria" do
        click_on('Enter another criteria')
      end

      within "#met-when-criteria" do
        fill_in("criteria-2", with: "more")
      end

      within "#workflow" do
        click_on_first_button("Save")
      end

      assert_requested request
      assert page.has_text?("Need updated"), "No success message displayed"
    end

    should "be able to delete met_when criteria" do
      @content_item["details"]["met_when"] = %w(win awesome more)
      publishing_api_has_item(@content_item)

      visit('/needs')
      click_on(format_need_goal(@content_item["details"]["goal"]))
      within "#workflow" do
        click_on("Edit")
      end

      met_when_initial_count = @content_item["details"]["met_when"].length
      assert met_when_initial_count >= 2

      @content_item["details"]["met_when"].each_with_index do |criteria, index|
        assert_equal(criteria, find_field("criteria-#{index}").value)
      end

      within "#met-when-criteria" do
        # delete criteria buttons
        assert page.has_selector?(:xpath, ".//button[@id='delete-criteria' and @value='0']")
        assert page.has_selector?(:xpath, ".//button[@id='delete-criteria' and @value='1']")
        assert page.has_selector?(:xpath, ".//button[@id='delete-criteria' and @value='2']")
      end

      within "#met-when-criteria" do
        click_on_first_button('delete-criteria')
      end

      assert_equal("awesome", find_field("criteria-0").value)
      assert_equal("more", find_field("criteria-1").value)

      within "#met-when-criteria" do
        assert page.has_no_selector?(:xpath, ".//button[@value='2']")
        assert page.has_no_field?("criteria-2")
      end
    end

    should "handle 422 errors from the Publishing API" do
      post_url = "#{Plek.find('publishing-api')}/v2/content/#{@content_item['content_id']}"
      stub_request(:put, post_url).to_return(status: 422)

      visit('/needs')

      click_on(format_need_goal(@content_item["details"]["goal"]))
      within "#workflow" do
        click_on("Edit")
      end

      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      within "#workflow" do
        click_on_first_button("Save")
      end

      assert page.has_content?("Edit need")
      assert page.has_text?("There was a problem saving your need.")
    end
  end

  context "updating a need which applies to all organisations" do
    setup do
      @content_item = create(:need_content_item)
      @content_item["details"]["applies_to_all_organisations"] = true
      publishing_api_has_content(
        [@content_item],
        Need.default_options.merge(
          per_page: 50
        )
      )
      publishing_api_has_linked_items(
        [],
        content_id: @content_item["content_id"],
        link_type: "meets_user_needs",
        fields: ["title", "base_path", "document_type"]
      )
      publishing_api_has_links(
        content_id: @content_item["content_id"],
        links: {
          organisations: []
        }
      )
      publishing_api_has_item(@content_item)
    end

    should "not show the organisations field" do
      visit "/needs"
      click_on(format_need_goal(@content_item["details"]["goal"]))

      within ".need-title" do
        assert page.has_content?(format_need_goal(@content_item["details"]["goal"]))
      end

      within ".nav-tabs" do
        assert page.has_link?("Edit", href: "/needs/#{@content_item['content_id']}/edit")
        click_on "Edit"
      end

      assert page.has_selector? "h3", text: "Edit need"
      assert page.has_no_select? "Organisations"
      assert page.has_content? "This need applies to all organisations"
    end
  end
end
