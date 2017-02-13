require_relative '../integration_test_helper'

class CreateANeedTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_editor
    publishing_api_has_content(
      [],
      Need.default_options.merge(
        per_page: 50
      )
    )
    @ministry_of_justice_content_id = SecureRandom.uuid
    publishing_api_has_linkables([
      {
        "content_id": SecureRandom.uuid,
        "title" => "Committee On Climate Change",
      },
      {
        "content_id": @ministry_of_justice_content_id,
        "title" => "Ministry Of Justice",
      }
    ], document_type: "organisation")
  end

  context "Creating a need" do
    should "be able to access 'Add a Need' page" do
      visit('/needs')
      within "#workflow" do
        click_on('Add a new need')
      end

      assert page.has_field?("As a")
      assert page.has_field?("I need to")
      assert page.has_field?("So that")
      assert page.has_text?("Departments and agencies")
      assert page.has_text?("Committee On Climate Change")

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
      payload = {
        schema_name: "need",
        publishing_app: "maslow",
        rendering_app: "info-frontend",
        locale: "en",
        base_path: "/needs/find-my-local-register-office",
        routes: [
          {
            path: "/needs/find-my-local-register-office",
            type: "exact"
          }
        ],
        document_type: "need",
        title: "As a User, I need to find my local register office, so that I can find records of birth, marriage or death",
        details: {
          yearly_user_contacts: 10000,
          yearly_site_views: 1000000,
          yearly_need_views: 1000,
          yearly_searches: 2000,
          met_when: [
            "Can download a birth certificate."
          ],
          justifications: [
            "It's something only government does",
            "It's straightforward advice that helps people to comply with their statutory obligations"
          ],
          role: "User",
          goal: "find my local register office",
          benefit: "I can find records of birth, marriage or death",
          impact: "Noticed by the average member of the public",
          legislation: "http://www.legislation.gov.uk/stuff\r\nhttp://www.legislation.gov.uk/stuff",
          other_evidence: "Free text evidence with lots more evidence"
        }
      }

      put_content_url = %r{\A#{Plek.find('publishing-api')}/v2/content}
      put_content_request = stub_request(:put, put_content_url).with(
        body: payload
      )
      patch_links_url = %r{\A#{Plek.find('publishing-api')}/v2/links}
      patch_links_request = stub_request(
        :patch,
        patch_links_url
      ).with(body: { links: { organisations: [@ministry_of_justice_content_id] } })

      get_url = %r{\A#{Plek.find('publishing-api')}/v2/content}
      get_request = stub_request(:get, put_content_url).to_return(
        body: payload.merge(publication_state: "draft").to_json
      )

      get_links_url = %r{\A#{Plek.find('publishing-api')}/v2/links}
      get_links_request = stub_request(:get, get_links_url).to_return(
        body: { links: { organisations: [@ministry_of_justice_content_id] } }.to_json
      )

      get_linked_url = %r{\A#{Plek.find('publishing-api')}/v2/linked}
      get_linked_request = stub_request(:get, get_linked_url).to_return(
        body: {}.to_json
      )

      visit('/needs')
      within "#workflow" do
        click_on('Add a new need')
      end

      fill_in("As a", with: "User")
      fill_in("I need to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")
      select("Ministry Of Justice", from: "Departments and agencies")
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
      assert_requested put_content_request
      assert_requested patch_links_request
      assert_equal("Find my local register office", page.find("h1").text)
      assert page.has_text?("Need created")
    end

    should "be able to add more met_when criteria" do
      visit('/needs')
      within "#workflow" do
        click_on('Add a new need')
      end

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
      within "#workflow" do
        click_on('Add a new need')
      end

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
      within "#workflow" do
        click_on('Add a new need')
      end

      click_on_first_button("Save")

      within "#met-when-criteria" do
        assert_equal("", find_field("criteria-0").value)
      end
    end

    should "handle 422 errors from the Need API" do
      put_url = %r{\A#{Plek.find('publishing-api')}/v2/content/}
      stub_request(:put, put_url).to_return(status: 422)

      visit('/needs')
      within "#workflow" do
        click_on('Add a new need')
      end

      fill_in("As a", with: "User")
      fill_in("I need to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")

      click_on_first_button("Save")

      assert page.has_text?("There was a problem saving your need.")
    end

    should "be able to save and add a new need" do
      test_need = Need.new(
        role: "User",
        goal: "find my local register office",
        benefit: "I can find records of birth, marriage or death"
      )
      payload = test_need.send(:publishing_api_payload)

      put_content_url = %r{\A#{Plek.find('publishing-api')}/v2/content}
      put_content_request = stub_request(:put, put_content_url).with(body: payload)

      patch_links_url = %r{\A#{Plek.find('publishing-api')}/v2/links}
      patch_links_request = stub_request(
        :patch,
        patch_links_url
      ).with(body: { links: { organisations: [] } })

      visit('/needs')
      within "#workflow" do
        click_on('Add a new need')
      end

      fill_in("As a", with: "User")
      fill_in("I need to", with: "find my local register office")
      fill_in("So that", with: "I can find records of birth, marriage or death")

      within "#workflow" do
        click_on("Save and add a new need")
      end

      assert_requested put_content_request
      assert_requested patch_links_request
      assert page.has_content?("Add a new need")
      assert page.has_content?("Need created")
    end
  end

  context "given a need which exists" do
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
      publishing_api_has_item(@content_item, version: 2)
    end

    should "be able to add a new need from the need page" do
      visit "/needs/#{@content_item["content_id"]}"
      within "#workflow" do
        assert page.has_link?("Add a new need", href: "/needs/new")
      end
    end

    should "be able to add a new need from the history page" do
      visit "/needs/#{@content_item["content_id"]}/revisions"
      within "#workflow" do
        assert page.has_link?("Add a new need", href: "/needs/new")
      end
    end
  end
end
