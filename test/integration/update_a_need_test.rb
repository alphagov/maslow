require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'

class UpdateANeedTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as(stub_user)
    need_api_has_organisations(
      "committee-on-climate-change" => "Committee on Climate Change",
      "competition-commission" => "Competition Commission",
      "ministry-of-justice" => "Ministry of Justice"
    )
    need_hash = {
      "id" => "100001",
      "role" => "parent",
      "goal" => "apply for a primary school place",
      "benefit" => "my child can start school",
      "organisations" => [],
      "revisions" => [
        {
          "action_type" => "update",
          "author" => {
            "name" => "Mickey Mouse",
            "email" => "mickey.mouse@test.com",
            "uid" => "m0u53"
          },
          "changes" => {
            "goal" => [ "apply for a secondary school place" ,"apply for a primary school place" ],
            "role" => [ nil, "parent" ]
          },
          "created_at" => "2013-05-01T00:00:00+00:00"
        },
        {
          "action_type" => "create",
          "author" => {
            "name" => "Donald Duck",
            "email" => "donald.duck@test.com",
            "uid" => "d0n4ld"
          },
          "changes" => {
            "goal" => [ "apply for a school place", "apply for a secondary school place" ],
            "role" => [ "grandparent", nil ]
          },
          "created_at" => "2013-01-01T00:00:00+00:00"
        }
      ]
    }
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
  end
end
