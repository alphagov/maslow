# encoding: UTF-8
require_relative '../integration_test_helper'

class UpdateANeedTest < ActionDispatch::IntegrationTest
  def need_hash
    {
      "id" => "100001",
      "role" => "parent",
      "goal" => "apply for a primary school place",
      "benefit" => "my child can start school",
      "met_when" => ["win","awesome","more"],
      "organisations" => [],
      "legislation" => "Blank Fields Act 2013",
      "revisions" => [],
      "applies_to_all_organisations" => false
    }
  end

  setup do
    login_as(stub_user)
    need_api_has_organisations(
      "committee-on-climate-change" => "Committee on Climate Change",
      "competition-commission" => "Competition Commission",
      "ministry-of-justice" => "Ministry of Justice"
    )
  end

  context "updating a need" do
    setup do
      need_api_has_needs([need_hash])  # For need list
      need_api_has_need(need_hash)  # For individual need
      content_api_has_artefacts_for_need_id("100001", [])
    end

    should "be able to access edit form" do
      visit('/needs')

      click_on("100001")
      click_on("Edit need")

      within ".breadcrumb" do
        assert page.has_link?("All needs", href: "/needs")
        assert page.has_link?("100001: Apply for a primary school place", href: "/needs/100001")
        assert page.has_content?("Edit")
      end

      assert page.has_content?("Edit need")

      assert page.has_field?("As a")
      assert page.has_field?("I need to")
      assert page.has_field?("So that")
      # Other fields are tested in create_a_need_test.rb
    end

    should "be able to update a need" do
      api_url = Plek.current.find('need-api') + '/needs/100001'
      request_body = blank_need_request.merge(
          "role" => "grandparent",
          "goal" => "apply for a primary school place",
          "benefit" => "my grandchild can start school",
          "legislation" => "",
          "met_when" => ["win","awesome","more"],
          "author" => {
            "name" => stub_user.name,
            "email" => stub_user.email,
            "uid" => stub_user.uid
          }
      ).to_json
      request = stub_request(:put, api_url).with(:body => request_body)

      visit('/needs')

      click_on('100001')
      click_on('Edit need')

      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      fill_in("What legislation underpins this need?", with: "")
      click_on_first("Update Need")

      assert_requested request
      assert page.has_text?("Need updated."), "No success message displayed"
    end

    should "display met_when criteria on multiple lines" do
      need_api_has_need(need_hash.merge("met_when" => ["win", "awesome"]))
      visit('/needs')
      click_on('100001')
      click_on("Edit need")

      within "#met-when-criteria" do
        assert_equal("win", find_field("criteria-0").value)
        assert_equal("awesome", find_field("criteria-1").value)
      end
    end

    should "be able to add more met_when criteria" do
      api_url = Plek.current.find('need-api') + '/needs/100001'
      request_body = blank_need_request.merge(
        "role" => "parent",
        "goal" => "apply for a primary school place",
        "benefit" => "my child can start school",
        "legislation" => "Blank Fields Act 2013",
        "met_when" => ["win","awesome","more"],
        "author" => {
          "name" => stub_user.name,
          "email" => stub_user.email,
          "uid" => stub_user.uid
        }
      ).to_json
      request = stub_request(:put, api_url).with(:body => request_body)

      visit('/needs')
      click_on('100001')
      click_on("Edit need")

      assert_equal("win", find_field("criteria-0").value)
      assert_equal("awesome", find_field("criteria-1").value)

      within "#met-when-criteria" do
        click_on('Add criteria')
      end

      within "#met-when-criteria" do
        fill_in("criteria-2", with: "more")
      end

      click_on_first("Update Need")

      assert_requested request
      assert page.has_text?("Need updated."), "No success message displayed"
    end

    should "be able to delete met_when criteria" do
      visit('/needs')
      click_on('100001')
      click_on("Edit need")

      assert_equal("win", find_field("criteria-0").value)
      assert_equal("awesome", find_field("criteria-1").value)
      assert_equal("more", find_field("criteria-2").value)

      within "#met-when-criteria" do
        # delete criteria buttons
        assert page.has_selector?(:xpath, ".//button[@id='delete-criteria' and @value='0']")
        assert page.has_selector?(:xpath, ".//button[@id='delete-criteria' and @value='1']")
        assert page.has_selector?(:xpath, ".//button[@id='delete-criteria' and @value='2']")
      end

      within "#met-when-criteria" do
        click_on_first('delete-criteria')
      end

      assert_equal("awesome", find_field("criteria-0").value)
      assert_equal("more", find_field("criteria-1").value)

      within "#met-when-criteria" do
        assert page.has_no_selector?(:xpath, ".//button[@value='2']")
        assert page.has_no_field?("criteria-2")
      end
    end

    should "handle 422 errors from the Need API" do
      api_url = Plek.current.find('need-api') + '/needs/100001'
      request_body = blank_need_request.merge(
        "role" => "grandparent",
        "goal" => "apply for a primary school place",
        "benefit" => "my grandchild can start school",
        "legislation" => "Blank Fields Act 2013",
        "met_when" => ["win","awesome","more"],
        "author" => {
          "name" => stub_user.name,
          "email" => stub_user.email,
          "uid" => stub_user.uid
        }
      ).to_json
      request = stub_request(:put, api_url)
                  .with(:body => request_body)
                  .to_return(
                    status: 422,
                    body: {
                      _response_info: { status: "invalid_attributes" },
                      errors: [ "error"]
                    }.to_json
                  )

      visit('/needs')

      click_on("100001")
      click_on("Edit need")

      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      click_on_first('Update Need')

      assert page.has_content?("Edit need")
      assert page.has_text?("There was a problem saving your need.")
    end
  end

  context "updating a need which applies to all organisations" do
    setup do
      @need = need_hash.merge(
        "id" => 100200,
        "applies_to_all_organisations" => true
      )

      need_api_has_needs([@need]) # For need list
      need_api_has_need(@need) # For individual need
      content_api_has_artefacts_for_need_id("100200", [])
    end

    should "not show the organisations field" do
      # stub the put request to the Need API
      request_body = blank_need_request.merge(
        "role" => "parent",
        "goal" => "apply for a primary school place",
        "organisation_ids" => [],
        "benefit" => "my child can start school",
        "legislation" => "Blank Fields Act 2013",
        "met_when" => ["win","awesome","more"],
        "author" => {
          "name" => stub_user.name,
          "email" => stub_user.email,
          "uid" => stub_user.uid
        }
      )
      request = stub_request(:put, Plek.current.find('need-api') + '/needs/100200')
                  .with(:body => request_body.to_json)

      visit "/needs"
      click_on "100200"

      within ".need header" do
        assert page.has_content? "Apply for a primary school place"
        click_on "Edit need"
      end

      assert page.has_selector? "h3", text: "Edit need"
      assert page.has_no_select? "Organisations"

      click_on_first "Update Need"
      assert_requested request
      assert page.has_content? "Need updated."
    end
  end
end
