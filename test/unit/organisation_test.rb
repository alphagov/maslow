require_relative '../test_helper'
require 'gds_api/organisations'

class OrganisationTest < ActiveSupport::TestCase
  context "loading organisations" do
    setup do
      @organisation_attrs = [
        {
          "title" => "Committee on Climate Change",
          "details" => {
            "slug" => "committee-on-climate-change",
            "abbreviation" => "CCC"
          },
        },
        {
          "title" => "Competition Commission",
          "details" => {
            "slug" => "competition-commission",
            "abbreviation" => "CC"
          }
        }
      ]
    end

    should "return organisations from the organisations api" do
      GdsApi::Organisations.any_instance.expects(:organisations)
        .returns(@organisation_attrs)
      organisations = Organisation.all

      assert_equal 2, organisations.size
      assert_equal(["committee-on-climate-change", "competition-commission"],
                   organisations.map(&:id))
      assert_equal(["Committee on Climate Change", "Competition Commission"],
                   organisations.map(&:name))
      assert_equal(%w(CCC CC),
                   organisations.map(&:abbreviation))
    end

    should "cache the organisation results" do
      GdsApi::Organisations.any_instance.expects(:organisations).once

      5.times do
        Organisation.all
      end
    end

    should "cache the organisation results, but only for an hour" do
      GdsApi::Organisations.any_instance.expects(:organisations).twice
      Organisation.all

      Timecop.travel(Time.zone.now + 61.minutes) do
        Organisation.all
      end
    end

    should "show the organisation abbreviation and status" do
      organisation = Organisation.new(title: "name", details: { slug: "slug", abbreviation: "abbr", govuk_status: "live" })
      assert_equal "name [abbr] (live)", organisation.name_with_abbreviation_and_status
    end

    should "not show the abbreviation if it is not present" do
      organisation = Organisation.new(title: "name", details: { slug: "slug", govuk_status: "exempt" })
      assert_equal "name (exempt)", organisation.name_with_abbreviation_and_status
    end

    should "not show the abbreviation if it is the same as the name" do
      organisation = Organisation.new(title: "name", details: { slug: "slug", abbreviation: "name", govuk_status: "joining" })
      assert_equal "name (joining)", organisation.name_with_abbreviation_and_status
    end
  end
end
