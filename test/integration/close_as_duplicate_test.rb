# encoding: UTF-8
require_relative '../integration_test_helper'

class CloseAsDuplicateTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_editor
    need_api_has_organisations([])
    @need = minimal_example_need(
      "id" => "100001",
      "goal" => "apply for a primary school place",
    )
    @duplicate = minimal_example_need(
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
      "duplicate_of" => 100001,
      "author" => {
        "name" => stub_user.name,
        "email" => stub_user.email,
        "uid" => stub_user.uid
      }
    }

    request = stub_request(:put, @api_url+'/closed').with(:body => request_body.to_json)

    visit "/needs"
    click_on "100002"
    click_on "Actions"
    within "#actions #duplicate" do
      click_on "Close as a duplicate"
    end

    fill_in("This need is a duplicate of", with: 100001)

    get_request = stub_request(:get, @api_url).to_return(
      :body =>
        { "_response_info" => { "status" => "ok" },
          "id" => "100002",
          "role" => "User",
          "goal" => "find my local register office",
          "benefit" => "I can find records of birth, marriage or death",
          "duplicate_of" => "100001",
          "status" => {
            "description" => "proposed"
          }
        }.to_json
    )
    need_api_has_need(@need)

    click_on "Close as a duplicate"


    assert page.has_no_button?("Edit")
    assert page.has_content?("Need closed as a duplicate of 100001: apply for a primary school place")
  end

  should "show an error message if there's a problem closing the need as a duplicate" do
    need_api_has_need(@duplicate) # For individual need
    request = stub_request(:put, @api_url+'/closed').to_return(status: 422)

    visit "/needs"
    click_on "100002"
    click_on "Actions"
    within "#actions #duplicate" do
      click_on "Close as a duplicate"
    end

    fill_in("This need is a duplicate of", with: 100001)
    click_on "Close as a duplicate"

    assert page.has_content?("There was a problem closing the need as a duplicate")
    assert page.has_link?("Close as a duplicate", href: close_as_duplicate_need_path(100002))
  end

  should "show an error message if no duplicate need ID is entered" do
    need_api_has_need(@duplicate) # For individual need
    request = stub_request(:put, @api_url+'/closed').to_return(status: 422)

    visit "/needs"
    click_on "100002"
    click_on "Actions"
    within "#actions #duplicate" do
      click_on "Close as a duplicate"
    end

    fill_in("This need is a duplicate of", with: "abc")
    click_on "Close as a duplicate"

    assert_requested request

    assert page.has_content?("There was a problem closing the need as a duplicate")
    assert page.has_link?("Close as a duplicate", href: close_as_duplicate_need_path(100002))
  end

  should "not be able to edit a closed need" do
    login_as_stub_editor

    @duplicate.merge!("duplicate_of" => "100001")
    need_api_has_need(@duplicate)
    need_api_has_need(@need)
    visit "/needs/100002/edit"

    assert page.has_content?("Closed needs cannot be edited")
    assert page.has_content?("This need is closed as a duplicate of 100001")
    assert page.has_link?("100001", href: "/needs/100001")
    assert page.has_no_link?("Edit")
  end

  should "not be able to edit a closed need from the history page" do
    @duplicate.merge!("duplicate_of" => "100001")
    need_api_has_need(@duplicate)
    need_api_has_need(@need)
    visit "/needs/100002/revisions"

    assert page.has_no_link?("Edit")
  end

  should "not be able to access close page if already closed" do
    @duplicate.merge!("duplicate_of" => "100001")
    need_api_has_need(@duplicate)
    need_api_has_need(@need)
    visit "/needs/100002/close-as-duplicate"

    assert page.has_no_link?("Edit")
    assert page.has_content?("This need is already closed")
  end

  should "be able to add a new need from this page" do
    need_api_has_need(@duplicate) # For individual need
    visit "/needs"
    click_on "100002"

    click_on "Actions"
    within "#workflow" do
      assert page.has_link?("Add a new need", href: "/needs/new")
    end

    within "#actions #duplicate" do
      click_on "Close as a duplicate"
    end

    within "#workflow" do
      assert page.has_link?("Add a new need", href: "/needs/new")
    end
  end
end
