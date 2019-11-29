require_relative "../test_helper"
require "gds_api/test_helpers/publishing_api_v2"

class NeedTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::PublishingApiV2

  setup do
    @stub_publishing_api_response = {
      "total" => 3,
      "pages" => 1,
      "current_page" => 1,
      "links" => [
        {
          "href" => "http://publishing-api.dev.gov.uk/v2/content?document_type=need&fields%5B%5D=content_id&fields%5B%5D=details&locale=en&order=-public_updated_at&per_page=50&publishing_app=need-api&page=2",
          "rel" => "next",
        },
        {
          "href" => "http://publishing-api.dev.gov.uk/v2/content?document_type=need&fields%5B%5D=content_id&fields%5B%5D=details&locale=en&order=-public_updated_at&per_page=50&publishing_app=need-api&page=1",
          "rel" => "self",
        },
      ],
      "results" => [
        {
          "content_id" => "0001c0c6-2dd3-4b56-87f1-815efe32c155",
          "publication_state" => "draft",
          "details" =>
          {
            "applies_to_all_organisations" => false,
            "benefit" => "I can make sure I'm getting what I'm entitled to",
            "goal" => "know what my rights are after a crime",
            "role" => "citizen",
          },
        },
        {
          "content_id" => "c867e5f7-2d68-42ad-bedb-20638b3bf58e",
          "publication_state" => "draft",
          "details" =>
          {
            "applies_to_all_organisations" => false,
            "benefit" => "I can improve their services or stop them from operating",
            "goal" => "complain about a legal adviser",
            "role" => "citizen",
          },
        },
        {
          "content_id" => "0925fd2b-6b59-4120-a849-96ab19b9c7df",
          "publication_state" => "published",
          "details" => {
            "applies_to_all_organisations" => false,
            "role" => "citizen",
            "goal" => "take my tax appeal to a tribunal",
            "benefit" => "I can have my case heard again and get the decision reversed",
          },
        },
      ],
    }
    @need_attributes1 = {
      "content_id" => "0001c0c6-2dd3-4b56-87f1-815efe32c155",
      "need_id" => 100523,
      "details" => {
        "benefit" => "I can make sure I'm getting what I'm entitled to",
        "goal" => "know what my rights are after a crime",
        "role" => "citizen",
      },
    }

    @need_attributes2 = {
      "content_id" => "c867e5f7-2d68-42ad-bedb-20638b3bf58e",
      "need_id" => 100522,
      "details" => {
        "benefit" => "I can improve their services or stop them from operating",
        "goal" => "complain about a legal adviser",
        "role" => "citizen",
      },
    }

    @need_attributes3 = {
      "content_id" => "0925fd2b-6b59-4120-a849-96ab19b9c7df",
      "need_id" => 100521,
      "details" => {
        "role" => "citizen",
        "goal" => "take my tax appeal to a tribunal",
        "benefit" => "I can have my case heard again and get the decision reversed",
      },
    }
  end

  context "saving need data to the Publishing API" do
    setup do
      @atts = {
        "content_id" => SecureRandom.uuid,
        "role" => "user",
        "goal" => "do stuff",
        "benefit" => "get stuff",
        "organisation_ids" => %w(ministry-of-justice),
        "impact" => "Endangers people",
        "justifications" => ["It's something only government does", "The government is legally obliged to provide it"],
        "met_when" => ["Winning", "Winning More"],
        "other_evidence" => "Ministerial priority",
        "legislation" => "Vehicle Excise and Registration Act 1994, schedule 4",
        "yearly_user_contacts" => 500,
        "yearly_site_views" => 70000,
        "yearly_need_views" => 15000,
        "yearly_searches" => 2000,
      }

      @need_content_item = create(:need_content_item)
    end

    context "given valid attributes" do
      should "make a request to the Publishing API" do
        publishing_api_has_links(
          content_id: @need_content_item["content_id"],
          links: { organisations: [] },
        )
        need = Need.need_from_publishing_api_payload(@need_content_item)

        stub_publishing_api_put_content(
          need.content_id,
          need.send(:publishing_api_payload),
          body: {
            content_id: @need_content_item["content_id"],
          },
        )
        stub_publishing_api_patch_links(need.content_id, links: { organisations: [] })

        assert need.save

        assert_publishing_api_put_content(need.content_id, need.send(:publishing_api_payload))
      end

      should "set the 'met_when', 'justifications' and 'organisation_ids' fields to be empty arrays if not present" do
        assert_equal [], Need.new({}).met_when
        assert_equal [], Need.new("met_when" => nil).met_when

        assert_equal [], Need.new({}).justifications
        assert_equal [], Need.new("justifications" => nil).justifications

        assert_equal [], Need.new({}).organisation_ids
        assert_equal [], Need.new("organisation_ids" => nil).organisation_ids
      end

      should "be able to add blank criteria" do
        need = Need.new({})

        need.add_more_criteria
        assert_equal [""], need.met_when

        need.add_more_criteria
        assert_equal ["", ""], need.met_when
      end

      should "be able to delete criteria" do
        need = Need.new("met_when" => %w(0 1 2))

        need.remove_criteria(0)
        assert_equal %w(1 2), need.met_when

        need.remove_criteria(1)
        assert_equal %w[1], need.met_when

        need.remove_criteria(0)
        assert_equal [], need.met_when
      end
    end

    should "be invalid when role is blank" do
      need = Need.new(@atts.merge("role" => ""))

      assert_not need.valid?
      assert need.errors.has_key?(:role)
    end

    should "be invalid when goal is blank" do
      need = Need.new(@atts.merge("goal" => ""))

      assert_not need.valid?
      assert need.errors.has_key?(:goal)
    end

    should "be invalid when benefit is blank" do
      need = Need.new(@atts.merge("benefit" => ""))

      assert_not need.valid?
      assert need.errors.has_key?(:benefit)
    end

    should "be invalid when justifications are not in the list" do
      need = Need.new(@atts.merge("justifications" => ["something else"]))

      assert_not need.valid?
      assert need.errors.has_key?(:justifications)
    end

    should "be invalid when impact is not in the list" do
      need = Need.new(@atts.merge("impact" => "something else"))

      assert_not need.valid?
      assert need.errors.has_key?(:impact)
    end

    should "be valid with a blank value for yearly_user_contacts" do
      need = Need.new(@atts.merge("yearly_user_contacts" => ""))

      assert need.valid?
    end

    should "be valid with a blank value for yearly_site_views" do
      need = Need.new(@atts.merge("yearly_site_views" => ""))

      assert need.valid?
    end

    should "be valid with a blank value for yearly_need_views" do
      need = Need.new(@atts.merge("yearly_need_views" => ""))

      assert need.valid?
    end

    should "be valid with a blank value for yearly_searches" do
      need = Need.new(@atts.merge("yearly_searches" => ""))

      assert need.valid?
    end

    should "report a problem if unable to save the need" do
      need = Need.new(@atts)
      GdsApi::PublishingApiV2.any_instance.expects(:put_content).raises(
        GdsApi::HTTPErrorResponse.new(422, %w[error]),
      )

      assert_equal false, need.save
    end
  end

  def stub_need_response
    {
      "results" => [{ "id" => 100001 }],
      "pages" => 2,
      "total" => 60,
      "page_size" => 50,
      "current_page" => 1,
      "start_index" => 1,
    }
  end

  context "listing needs" do
    should "call the Publishing API V2 adapter and return a list of needs" do
      request_params = {
        document_type: "need",
        per_page: 50,
        fields: %w(content_id details publication_state),
        locale: "en",
        order: "-updated_at",
      }

      publishing_api_has_links(
        content_id: @need_attributes1["content_id"],
        links: { organisations: [] },
      )
      publishing_api_has_links(
        content_id: @need_attributes2["content_id"],
        links: { organisations: [] },
      )
      publishing_api_has_links(
        content_id: @need_attributes3["content_id"],
        links: { organisations: [] },
      )


      needs = [
        Need.new(@need_attributes1["details"]),
        Need.new(@need_attributes2["details"]),
        Need.new(@need_attributes3["details"]),
      ]

      publishing_api_has_content(
        needs,
        Need.default_options.merge(
          per_page: 50,
        ),
      )

      GdsApi::PublishingApiV2.any_instance.expects(:get_content_items)
        .with(request_params)
        .returns(@stub_publishing_api_response)

      list = Need.list

      assert 3, list.length
      assert(list.all? { |need| need.is_a? Need })
    end

    should "retain pagination info" do
      multipage_response = @stub_publishing_api_response
      multipage_response["total"] = 60
      multipage_response["per_page"] = 50
      multipage_response["pages"] = 2
      multipage_response["page"] = 1

      GdsApi::PublishingApiV2.any_instance.expects(:get_content_items).once.returns(multipage_response)

      @stub_publishing_api_response["results"].each do |need|
        publishing_api_has_links(
          content_id: need["content_id"],
          links: { organisations: [] },
        )
      end

      need_list = Need.list

      assert_equal 2, need_list.pages
      assert_equal 60, need_list.total
      assert_equal 50, need_list.per_page
      assert_equal 1, need_list.current_page
    end
  end

  context "requesting needs by content_ids" do
    setup do
      @need1 = create(:need_content_item)
      @need2 = create(:need_content_item)
      publishing_api_has_item(@need1)
      publishing_api_has_item(@need2)
    end

    should "return an array of matching Need objects" do
      publishing_api_has_links(
        content_id: @need1["content_id"],
        links: { organisations: [] },
      )

      publishing_api_has_links(
        content_id: @need2["content_id"],
        links: { organisations: [] },
      )

      needs = Need.by_content_ids(@need1["content_id"], @need2["content_id"])

      assert_equal 2, needs.size
      assert_equal [@need1["content_id"], @need2["content_id"]], needs.map(&:content_id)
    end
  end

  def stub_response(additional_atts = {})
    response_hash = {
      "_response_info" => { "status" => "ok" },
      "id" => 100001,
      "role" => "person",
      "goal" => "do things",
      "benefit" => "good things",
    }.merge(additional_atts)
    stub("response", to_hash: response_hash)
  end

  context "loading needs" do
    should "construct a need from an API response" do
      content_id = SecureRandom.uuid
      need_content_item = create(
        :need_content_item,
        content_id: content_id,
        details: {
          need_id: 100001,
          role: "human",
          goal: "I want to do something",
          benefit: "so that I can be happy",
        },
      )

      publishing_api_has_item(need_content_item)
      publishing_api_has_links(
        content_id: content_id,
        links: { organisations: [] },
      )

      need = Need.find(content_id)

      assert_equal content_id, need.content_id
      assert_equal 100001, need.need_id
      assert_equal "human", need.role
      assert_equal "I want to do something", need.goal
      assert_equal "so that I can be happy", need.benefit
    end

    should "return organisations for a need" do
      first_organisation_content_id = SecureRandom.uuid
      second_organisation_content_id = SecureRandom.uuid
      response = [
        {
          title: "Her Majesty's Revenue and Customs",
          content_id: first_organisation_content_id,
        },
        {
          title: "Department of Transport",
          content_id: second_organisation_content_id,
        },
      ]

      content_id = SecureRandom.uuid
      need_content_item = create(:need_content_item, content_id: content_id)
      publishing_api_has_item(need_content_item)

      publishing_api_has_links(
        content_id: content_id,
        links: {
          organisations: [
            first_organisation_content_id,
            second_organisation_content_id,
          ],
        },
      )

      publishing_api_has_linkables(
        response,
        document_type: "organisation",
      )

      need = Need.find(content_id)
      organisations = need.organisations

      assert_equal 2, organisations.count

      first_organisation = organisations.first
      second_organisation = organisations[1]

      assert_equal first_organisation_content_id, first_organisation.content_id
      assert_equal second_organisation_content_id, second_organisation.content_id
    end

    should "return revisions for a need" do
      stub_response(
        "revisions" => [
          {
            "action_type" => "update",
            "author" => {
              "name" => "Jack Bauer",
              "email" => "jack.bauer@test.com",
            },
            "changes" => {
              "goal" => ["apply for a secondary school place", "apply for a primary school place"],
              "role" => [nil, "parent"],
            },
            "created_at" => "2013-05-01T00:00:00+00:00",
          },
          {
            "action_type" => "create",
            "author" => {
              "name" => "Jack Sparrow",
              "email" => "jack.sparrow@test.com",
            },
            "changes" => {
              "goal" => ["apply for a school place", "apply for a secondary school place"],
              "role" => ["grandparent", nil],
            },
            "created_at" => "2013-01-01T00:00:00+00:00",
          },
        ],
      )

      content_id = SecureRandom.uuid
      need_content_item1 = create(
        :need_content_item,
        content_id: content_id,
        publication_state: "superseded",
        user_facing_version: 1,
      )
      need_content_item2 = create(
        :need_content_item,
        content_id: content_id,
        publication_state: "superseded",
        details: {
          goal: "how to make a claim on an estate",
        },
        user_facing_version: 2,
      )
      need_content_item3 = create(
        :need_content_item,
        content_id: content_id,
        publication_state: "published",
        details: {
          goal: "how to make a claim on an estate",
        },
        user_facing_version: 3,
      )

      publishing_api_has_item(need_content_item3)
      publishing_api_has_item(
        need_content_item1,
        version: need_content_item1["user_facing_version"].to_s,
      )
      publishing_api_has_item(
        need_content_item2,
        version: need_content_item2["user_facing_version"].to_s,
      )

      publishing_api_has_links(
        content_id: content_id,
        links: {
          organisations: [],
        },
      )

      need = Need.find(content_id)

      assert_equal 3, need.revisions.count

      first_revision = need.revisions.first
      second_revision = need.revisions[1]

      assert_equal %w(publication_state), first_revision["changes"].keys
      assert_equal %w(superseded published), first_revision["changes"]["publication_state"]
      assert_equal %w(goal), second_revision["changes"].keys
      assert_equal(
        [
          "find out if an estate is claimable and how to make a claim on an estate",
          "how to make a claim on an estate",
        ],
        second_revision["changes"]["goal"],
      )
    end

    should "raise an error when need not found" do
      content_id = SecureRandom.uuid

      GdsApi::PublishingApiV2.any_instance.expects(:get_content).once
        .with(content_id)
        .raises(GdsApi::HTTPNotFound.new(404))

      assert_raises Need::NotFound do
        Need.find(content_id)
      end
    end
  end

  context "updating needs" do
    setup do
      @need_content_item = create(
        :need_content_item,
        content_id: "3e5aa539-79a1-4714-8714-4e3037f981bd",
      )
      publishing_api_has_links(
        content_id: @need_content_item["content_id"],
        links: { organisations: [] },
      )
      @need = Need.need_from_publishing_api_payload(@need_content_item)
    end

    context "updating fields" do
      should "update fields and send to the Publishing API" do
        @need.update(
          impact: "Endangers people",
          yearly_searches: 50000,
        )

        stub_publishing_api_put_content(
          @need_content_item["content_id"],
          @need.send(:publishing_api_payload),
          body: {
            content_id: @need_content_item["content_id"],
            impact: "Endangers people",
            yearly_searches: 50000,
          },
        )

        stub_publishing_api_patch_links(
          @need_content_item["content_id"],
          links: { organisations: [] },
        )

        @need.save

        assert_equal "find out if an estate is claimable and how to make a claim on an estate", @need.goal
        assert_equal "Endangers people", @need.impact
        assert_equal 50000, @need.yearly_searches

        assert_publishing_api_put_content(@need_content_item["content_id"], @need.send(:publishing_api_payload))
      end

      should "strip leading newline characters from textareas" do
        @need.update(
          "legislation": "\nRemove the newline from legislation",
          "other_evidence": "\nRemove the newline from other_evidence",
        )

        stub_publishing_api_put_content(
          @need.content_id,
          @need.send(:publishing_api_payload),
          body: {
            "content_id": @need_content_item["content_id"],
                 "legislation": "\nRemove the newline from legislation",
                 "other_evidence": "\nRemove the newline from other_evidence",
          },
        )
        stub_publishing_api_patch_links(@need.content_id, links: { organisations: [] })
        @need.save

        assert_equal "Remove the newline from legislation", @need.legislation
        assert_equal "Remove the newline from other_evidence", @need.other_evidence
      end
    end
  end

  context "closing needs as duplicates" do
    should "call Publishing API with the correct values" do
      need_content_item = create(
        :need_content_item,
        need_id: 100001,
      )

      need_content_item_duplicate = create(
        :need_content_item,
        need_id: 100002,
      )

      explanation = "Duplicate of #{need_content_item['content_id']}"

      stub_publishing_api_unpublish(
        need_content_item_duplicate["content_id"],
        query: {
        },
        "body": {
          "type": "withdrawal",
          explanation: explanation,
        },
      )

      publishing_api_has_links(
        content_id: need_content_item_duplicate["content_id"],
        links: { organisations: [] },
      )

      need = Need.need_from_publishing_api_payload(need_content_item_duplicate)
      need.unpublish(explanation)

      assert_publishing_api_unpublish(need.content_id, nil, 1)
    end
  end

  context "reopening closed needs" do
    should "call Publishing API with the correct values" do
      need = create(
        :need_content_item,
        content_id: "f844c60e-05f9-4585-9c0f-fd48099ce81b",
        publication_state: "unpublished",
      )

      publishing_api_has_links(
        content_id: need["content_id"],
        links: { organisations: [] },
      )

      need_record = Need.need_from_publishing_api_payload(need)
      need_from_publishing_api = need_record.send(:publishing_api_payload)

      stub_publishing_api_put_content(
        need["content_id"],
        need_from_publishing_api,
        body: {
          content_id: need["content_id"],
        },
      )
      stub_publishing_api_patch_links(need["content_id"], links: { organisations: [] })
      stub_publishing_api_publish(need["content_id"], update_type: "major")

      need_record.publish

      assert_publishing_api_publish(need["content_id"], update_type: "major")
    end
  end
end
