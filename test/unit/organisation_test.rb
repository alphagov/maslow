require_relative "../test_helper"
require "gds_api/organisations"

class OrganisationTest < ActiveSupport::TestCase
  context "loading organisations" do
    setup do
      stub_publishing_api_has_linkables(
        [
          {
            "content_id": SecureRandom.uuid,
            "title" => "Committee on Climate Change",
          },
          {
            "content_id": SecureRandom.uuid,
            "title" => "Competition Commission",
          },
        ],
        document_type: "organisation",
      )

      @linkables_request_path =
        "#{Plek.current.find('publishing-api')}/v2/linkables?document_type=organisation"
    end

    should "return organisations from the organisations api" do
      organisations = Organisation.all

      assert_equal 2, organisations.size
      assert_equal(
        ["Committee on Climate Change", "Competition Commission"],
        organisations.map(&:title),
      )
    end

    should "cache the organisation results" do
      5.times do
        Organisation.all
      end

      assert_requested(:get, @linkables_request_path, times: 1)
    end

    should "cache the organisation results, but only for an hour" do
      Organisation.all

      Timecop.travel(Time.zone.now + 61.minutes) do
        Organisation.all
      end
    end

    should "show the title and publication state" do
      organisation = Organisation.new(title: "name", publication_state: "draft")
      assert_equal "name (draft)", organisation.title_and_publication_state
    end
  end
end
