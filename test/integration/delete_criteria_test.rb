require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'

class DeleteCriteriaTest < ActionDispatch::IntegrationTest
  include GdsApi::TestHelpers::NeedApi

  def need_hash
    {
      "id" => "100001",
      "role" => "parent",
      "goal" => "apply for a primary school place",
      "benefit" => "my child can start school",
      "met_when" => ["win","awesome","more"],
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
    need_api_has_needs([need_hash])
    need_api_has_need(need_hash)
  end

  should "be able to delete met_when criteria" do
    visit('/needs')
    click_on('100001')

    assert_equal("win", find_field("criteria-0").value)
    assert_equal("awesome", find_field("criteria-1").value)
    assert_equal("more", find_field("criteria-2").value)

    assert page.has_button?("delete-criteria-0")
    assert page.has_button?("delete-criteria-1")
    assert page.has_button?("delete-criteria-2")

    within "#met-when-criteria" do
      click_on('delete-criteria-0')
    end

    assert_equal("awesome", find_field("criteria-0").value)
    assert_equal("more", find_field("criteria-1").value)

    assert page.has_no_field?("delete-criteria-2")
    assert page.has_no_field?("criteria-2")
  end
end
