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
      click_on("Edit")

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
          "legislation" => nil,
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
      click_on('Edit')

      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      fill_in("What legislation underpins this need?", with: "")
      click_on_first_button("Update Need")

      assert_requested request
      assert page.has_text?("Need updated."), "No success message displayed"
    end

    should "display met_when criteria on multiple lines" do
      need_api_has_need(need_hash.merge("met_when" => ["win", "awesome"]))
      visit('/needs')
      click_on('100001')
      click_on("Edit")

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
      click_on("Edit")

      assert_equal("win", find_field("criteria-0").value)
      assert_equal("awesome", find_field("criteria-1").value)

      within "#met-when-criteria" do
        click_on('Add criteria')
      end

      within "#met-when-criteria" do
        fill_in("criteria-2", with: "more")
      end

      click_on_first_button("Update Need")

      assert_requested request
      assert page.has_text?("Need updated."), "No success message displayed"
    end

    should "be able to delete met_when criteria" do
      visit('/needs')
      click_on('100001')
      click_on("Edit")

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
        click_on_first_button('delete-criteria')
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
      click_on("Edit")

      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      click_on_first_button('Update Need')

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
        click_on "Edit"
      end

      assert page.has_selector? "h3", text: "Edit need"
      assert page.has_no_select? "Organisations"
      assert page.has_content? "This need applies to all organisations"

      click_on_first_button "Update Need"
      assert_requested request
      assert page.has_content? "Need updated."
    end
  end

  context "marking a need as out of scope" do
    setup do
      @need = need_hash.merge(
        "in_scope" => nil
      )
      need_api_has_needs([@need]) # For need list
      content_api_has_artefacts_for_need_id("100001", [])

      @api_url = Plek.current.find('need-api') + '/needs/100001'
    end

    should "be able to mark a need as out of scope" do
      need_api_has_need(@need) # For individual need

      request_body = blank_need_request.merge(
        "role" => "parent",
        "goal" => "apply for a primary school place",
        "benefit" => "my child can start school",
        "legislation" => "Blank Fields Act 2013",
        "met_when" => ["win","awesome","more"],
        "in_scope" => false,
        "author" => {
          "name" => stub_user.name,
          "email" => stub_user.email,
          "uid" => stub_user.uid
        }
      )
      request = stub_request(:put, @api_url).with(:body => request_body.to_json)

      visit "/needs"
      click_on "100001"

      within ".need header" do
        click_on "Mark as out of scope"
      end

      click_on "Mark as out of scope"

      assert page.has_content?("Need has been marked as out of scope")
    end

    should "show an error message if there's a problem marking a need as out of scope" do
      need_api_has_need(@need) # For individual need
      request = stub_request(:put, @api_url).to_return(status: 422)

      visit "/needs"
      click_on "100001"

      within ".need header" do
        click_on "Mark as out of scope"
      end

      click_on "Mark as out of scope"

      assert page.has_content?("We had a problem marking the need as out of scope")
    end
  end

  context "closing a need as a duplicate" do
    setup do
      @need = need_hash
      @duplicate = need_hash.merge(
        "duplicate_of" => nil,
        "id" => "100002"
      )
      need_api_has_needs([@need,@duplicate]) # For need list
      content_api_has_artefacts_for_need_id("100002", [])

      @api_url = Plek.current.find('need-api') + '/needs/100002'
    end

    should "be able to close a need as a duplicate" do
      need_api_has_need(@duplicate) # For individual need
      request_body = {
        "duplicate_of" => "100001",
        "author" => {
          "name" => stub_user.name,
          "email" => stub_user.email,
          "uid" => stub_user.uid
        }
      }

      request = stub_request(:put, @api_url+'/closed').with(:body => request_body.to_json)

      visit "/needs"
      click_on "100002"
      click_on "Edit"
      fill_in("Duplicate of", with: 100001)

      get_request = stub_request(:get, @api_url).to_return(
        :body =>
          { "_response_info" => { "status" => "ok" },
            "id" => "100002",
            "role" => "User",
            "goal" => "find my local register office",
            "benefit" => "I can find records of birth, marriage or death",
            "duplicate_of" => "100001"
          }.to_json
      )

      click_on_first_button("Close as duplicate")

      assert page.has_content?("Need closed as a duplicate of 100001")
      assert page.has_no_button?("Edit")
    end

    should "show an error message if there's a problem closing the need as a duplicate" do
      need_api_has_need(@duplicate) # For individual need
      request = stub_request(:put, @api_url+'/closed').to_return(status: 422)

      visit "/needs"
      click_on "100002"
      click_on "Edit"
      fill_in("Duplicate of", with: 100001)
      click_on_first_button "Close as duplicate"

      assert page.has_content?("There was a problem closing the need as a duplicate")
    end

    should "not be able to edit a closed need" do
      @duplicate.merge!("duplicate_of" => "100001")
      need_api_has_need(@duplicate)
      visit "/needs/100002/edit"

      assert page.has_content?("Closed needs cannot be edited")
      assert page.has_content?("This need is a duplicate of 100001")
      assert page.has_link?("100001", href: "/needs/100001")
      assert page.has_no_button?("Edit")
    end

    should "not be able to edit a closed need from the history page" do
      @duplicate.merge!("duplicate_of" => "100001")
      need_api_has_need(@duplicate)
      visit "/needs/100002/revisions"

      assert page.has_content?("This need is a duplicate of 100001")
      assert page.has_link?("100001", href: "/needs/100001")
      assert page.has_no_button?("Edit")
    end
  end
end
