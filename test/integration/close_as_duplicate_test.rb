# encoding: UTF-8
require_relative '../integration_test_helper'

class CloseAsDuplicateTest < ActionDispatch::IntegrationTest
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
      click_on "Actions"
      click_on "Close as a duplicate"

      fill_in("This need is a duplicate of", with: 100001)

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
      need_api_has_need(@need)
      click_on_first_button("Close as a duplicate")


      assert page.has_content?("Need closed as a duplicate of 100001: apply for a primary school place")
      assert page.has_no_button?("Edit")
    end

    should "show an error message if there's a problem closing the need as a duplicate" do
      need_api_has_need(@duplicate) # For individual need
      request = stub_request(:put, @api_url+'/closed').to_return(status: 422)

      visit "/needs"
      click_on "100002"
      click_on "Actions"
      click_on "Close as a duplicate"

      fill_in("This need is a duplicate of", with: 100001)
      click_on_first_button "Close as a duplicate"

      assert page.has_content?("There was a problem closing the need as a duplicate")
      assert page.has_link?("Close as a duplicate", href: close_as_duplicate_need_path(100002))
    end

    should "not be able to edit a closed need" do
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
  end
end
