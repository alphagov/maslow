# encoding: UTF-8
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
      "met_when" => ["win","awesome"],
      "organisations" => [],
      "legislation" => "Blank Fields Act 2013",
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
            "role" => [ nil, "parent" ],
          },
          "created_at" => "2013-05-01T13:00:00+00:00"
        },
        {
          "action_type" => "update",
          "author" => nil,
          "changes" => {
            "legislation" => [ "foo", "bar" ]
          },
          "created_at" => "2013-04-01T13:00:00+00:00"
        },
        {
          "action_type" => "create",
          "author" => {
            "name" => "Donald Duck",
            "email" => nil,
            "uid" => nil
          },
          "changes" => {
            "goal" => [ "apply for a school place", "apply for a secondary school place" ],
            "role" => [ "grandparent", nil ]
          },
          "created_at" => "2013-01-01T13:00:00+00:00"
        }
      ]
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
      assert page.has_field?("I need to")
      assert page.has_field?("So that")
      # Other fields are tested in create_a_need_test.rb
    end

    should "leave met_when criteria unchanged" do
      need_api_has_need(need_hash.merge("met_when" => ["win", "awesome"]))
      visit('/needs')
      click_on('100001')

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

    should "be able to update a need" do
      api_url = Plek.current.find('need-api') + '/needs/100001'
      request_body = blank_need_request.merge(
          "role" => "grandparent",
          "goal" => "apply for a primary school place",
          "benefit" => "my grandchild can start school",
          "legislation" => "",
          "met_when" => ["win","awesome"],
          "author" => {
            "name" => stub_user.name,
            "email" => stub_user.email,
            "uid" => stub_user.uid
          }
      ).to_json
      request = stub_request(:put, api_url).with(:body => request_body)

      visit('/needs')

      click_on('100001')
      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      fill_in("What legislation underpins this need?", with: "")
      click_on_first("Update Need")

      assert_requested request
      assert page.has_text?("Need updated."), "No success message displayed"
    end

    should "handle 422 errors from the Need API" do
      api_url = Plek.current.find('need-api') + '/needs/100001'
      request_body = blank_need_request.merge(
        "role" => "grandparent",
        "goal" => "apply for a primary school place",
        "benefit" => "my grandchild can start school",
        "legislation" => "Blank Fields Act 2013",
        "met_when" => ["win","awesome"],
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
      click_on('100001')
      fill_in("As a", with: "grandparent")
      fill_in("So that", with: "my grandchild can start school")
      click_on_first('Update Need')

      assert page.has_css?("h1", text: "Edit a need")
      assert page.has_text?("There was a problem saving your need.")
    end

    should "see a list of recent revisions" do
      visit "/needs/100001"

      within "#revisions" do
        assert_equal 3, page.all("li.revision").count

        within "li.revision:nth-child(1)" do
          assert page.has_content?("Update by Mickey Mouse <mickey.mouse@test.com>")
          assert page.has_content?("1 May 2013, 13:00")

          within "ul.changes" do
            assert_equal 2, page.all("li").count

            assert page.has_content?("Goal: apply for a secondary school place → apply for a primary school place")
            assert page.has_content?("Role: blank → parent")
          end
        end

        within "li.revision:nth-child(2)" do
          assert page.has_content?("Update by unknown author")
          assert page.has_no_content?("<>") # catch missing email
          assert page.has_content?("1 April 2013, 13:00")
        end

        within "li.revision:nth-child(3)" do
          assert page.has_content?("Create by Donald Duck")
          assert page.has_no_content?("<>") # catch an empty email string
          assert page.has_content?("1 January 2013, 13:00")

          within "ul.changes" do
            assert_equal 2, page.all("li").count

            assert page.has_content?("Goal: apply for a school place → apply for a secondary school place")
            assert page.has_content?("Role: grandparent → blank")
          end
        end
      end
    end

  end
end
