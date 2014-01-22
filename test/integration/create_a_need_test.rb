require_relative '../integration_test_helper'

class CreateANeedTest < ActionDispatch::IntegrationTest

  setup do
    login_as(stub_user)
    need_api_has_organisations(
      "committee-on-climate-change" => {"name"=>"Committee on Climate Change",
                                        "abbreviation"=>"CCC"},
      "competition-commission" => {"name"=>"Competition Commission",
                                   "abbreviation"=>"CC"},
      "ministry-of-justice" => {"name"=>"Ministry of Justice",
                                "abbreviation"=>"MOJ"},
    )
    need_api_has_needs([])
  end

  context "Creating a need" do
    should "be able to access 'Add a Need' page" do
      visit('/needs')
      click_on('Add a new need')

      assert page.has_field?("As a")
      assert page.has_field?("I need to")
      assert page.has_field?("So that")
      assert page.has_text?("Departments and agencies")
      assert page.has_text?("Competition Commission")
      assert page.has_text?("Committee on Climate Change")

      assert page.has_text?("Is this need in proposition for GOV.UK? You can tick more than one.")
      Need::JUSTIFICATIONS.each do |just|
        assert page.has_unchecked_field?(just), "Missing justification: #{just}"
      end

      assert page.has_text?("What is the impact of GOV.UK not doing this?")
      Need::IMPACT.each do |impact|
        assert page.has_unchecked_field?(impact), "Missing impact: #{impact}"
      end

      assert page.has_text?("Need is likely to be met when")

      assert page.has_text?("Do you have any other evidence to support this need?")
      assert page.has_text?("Roughly how many user contacts do you get about this need per year")
      assert page.has_text?("Pageviews specific to this need per year")
      assert page.has_text?("Pageviews for your website per year")
      assert page.has_text?("How many searches relevant to this need are carried out per year")
      assert page.has_text?("What legislation underpins this need?")
    end

    should "be able to create a new Need" do
      post_request = stub_request(:post, Plek.current.find('need-api')+'/needs').with(
        :body => {
          "role" => "User",
          "goal" => "find my local register office",
          "benefit" => "I can find records of birth, marriage or death",
          "organisation_ids" => ["ministry-of-justice"],
          "impact" => "Noticed by the average member of the public",
          "justifications" => ["It's something only government does",
                               "It's straightforward advice that helps people to comply with their statutory obligations"],
          "met_when" => ["Can download a birth certificate."],
          "other_evidence" => "Free text evidence with lots more evidence",
          "legislation" => "http://www.legislation.gov.uk/stuff\nhttp://www.legislation.gov.uk/stuff",
          "yearly_user_contacts" => 10000,
          "yearly_site_views" => 1000000,
          "yearly_need_views" => 1000,
          "yearly_searches" => 2000,
          "in_scope" => nil,
          "duplicate_of" => nil,
          "author" => {
            "name" => stub_user.name,
            "email" => stub_user.email,
            "uid" => stub_user.uid
          }
        }.to_json
      ).to_return(
        :body =>
          { "_response_info" => { "status" => "created" },
            "id" => "100001"
          }.to_json
      )

      get_request = stub_request(:get, Plek.current.find('need-api')+'/needs/100001').to_return(
        :body =>
          { "_response_info" => { "status" => "ok" },
            "id" => "100001",
            "role" => "User",
            "goal" => "find my local register office",
            "benefit" => "I can find records of birth, marriage or death"
          }.to_json
      )

      content_api_has_artefacts_for_need_id(100001, [])

      visit('/needs')
      click_on('Add a new need')

      fill_in("As a", with: "User")
      fill_in("I need to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")
      select("Ministry of Justice [MOJ]", from: "Departments and agencies")
      check("It's straightforward advice that helps people to comply with their statutory obligations")
      check("It's something only government does")
      choose("Noticed by the average member of the public")
      fill_in("Do you have any other evidence to support this need?", with: "Free text evidence with lots more evidence")
      fill_in("Roughly how many user contacts do you get about this need per year", with: 10000)
      fill_in("Pageviews specific to this need per year", with: 1000)
      fill_in("Pageviews for your website per year", with: 1000000)
      fill_in("How many searches relevant to this need are carried out per year", with: 2000)
      fill_in("What legislation underpins this need?", with: "http://www.legislation.gov.uk/stuff\nhttp://www.legislation.gov.uk/stuff")
      within "#met-when-criteria" do
        fill_in("criteria-0", with: "Can download a birth certificate.")
      end

      click_on_first_button("Save")
      assert_requested post_request
      assert_requested get_request
      assert_equal("Find my local register office", page.find("h1").text)
      assert page.has_text?("Need created.")
    end

    should "be able to add more met_when criteria" do
      visit('/needs')
      click_on("Add a new need")

      assert page.has_field?("criteria-0")
      assert page.has_no_field?("delete-criteria")

      within "#met-when-criteria" do
        fill_in("criteria-0", with: "New Criteria")
        click_on('Enter another criteria')
      end

      within "#met-when-criteria" do
        assert_equal("New Criteria", find_field("criteria-0").value)
        assert page.has_field?("criteria-1")
      end
    end

    should "retain previous values when the need content is incomplete" do
      visit('/needs')
      click_on('Add a new need')

      fill_in("As a", with: "User")
      check("It's something only government does")
      within "#met-when-criteria" do
        fill_in("criteria-0", with: "Can download a birth certificate.")
      end

      click_on_first_button("Save")

      assert page.has_text?("Please fill in the required fields.")
      within "#met-when-criteria" do
        assert_equal("Can download a birth certificate.",
                     find_field("criteria-0").value)
      end
    end

    should "not have any fields filled in when submitting a blank form" do
      visit('/needs')
      click_on('Add a new need')

      click_on_first_button("Save")

      within "#met-when-criteria" do
        assert_equal("", find_field("criteria-0").value)
      end
    end

    should "handle 422 errors from the Need API" do
      request_body = blank_need_request.merge(
        "role" => "User",
        "goal" => "find my local register office",
        "benefit" => "I can find records of birth, marriage or death",
        "author" => {
          "name" => stub_user.name,
          "email" => stub_user.email,
          "uid" => stub_user.uid
        }
      ).to_json

      stub_request(:post, Plek.current.find('need-api')+'/needs')
                    .with(:body => request_body)
                    .to_return(status: 422, body: { _response_info: { status: "invalid_attributes" }, errors: [ "error"] }.to_json)

      visit('/needs')
      click_on('Add a new need')

      fill_in("As a", with: "User")
      fill_in("I need to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")

      click_on_first_button("Save")

      assert page.has_text?("There was a problem saving your need.")
    end
  end

end
