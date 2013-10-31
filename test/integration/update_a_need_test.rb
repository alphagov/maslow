require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'

class UpdateANeedTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::NeedApi

  def need_hash
    {
      "id" => "100001",
      "role" => "parent",
      "goal" => "apply for a primary school place",
      "benefit" => "my child can start school",
      "organisations" => []
    }
  end

  setup do
    login_as(stub_user)
    need_api_has_organisations(
      "committee-on-climate-change" => "Committee on Climate Change",
      "competition-commission" => "Competition Commission",
      "ministry-of-justice" => "Ministry of Justice"
    )
    need_api_has_needs([need_hash])  # For need list
    need_api_has_need(need_hash)  # For individual need
  end

  context "Updating a need" do
    should "be able to access edit form" do
      visit('/needs')
      click_on('100001')

      assert page.has_field?("As a")
      assert page.has_field?("I want to")
      assert page.has_field?("So that")
      # Other fields are tested in create_a_need_test.rb
    end

    should "split 'met when' criteria onto separate lines" do
      need_api_has_need(need_hash.merge("met_when" => ["win", "awesome"]))
      visit('/needs')
      click_on('100001')
      assert page.has_field?(
        "Need is likely to be met when",
        with: "win\nawesome"
      )
    end

    should "be able to update a need" do
      api_url = Plek.current.find('need-api') + '/needs/100001'
      request = stub_request(:put, api_url).with(
        :body => {
          "role" => "grandparent",
          "goal" => "apply for a primary school place",
          "benefit" => "my grandchild can start school",
          "author" => {
            "name" => stub_user.name,
            "email" => stub_user.email,
            "uid" => stub_user.uid
          }
      }.to_json)
      visit('/needs')
      click_on('100001')
      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      click_on_first("Update Need")

      assert_requested request

      assert page.has_text?("Need updated."), "No success message displayed"
    end

    should "handle 422 errors from the Need API" do
      api_url = Plek.current.find('need-api') + '/needs/100001'
      request_body = {
        "role" => "grandparent",
        "goal" => "apply for a primary school place",
        "benefit" => "my grandchild can start school",
        "author" => {
          "name" => stub_user.name,
          "email" => stub_user.email,
          "uid" => stub_user.uid
        }
      }.to_json
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
      click_on('100001')
      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      click_on_first('Update Need')

      assert page.has_css?("h1", text: "Edit a need")
      assert page.has_text?("There was a problem saving your need.")
    end
  end
end
