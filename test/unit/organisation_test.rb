require_relative '../test_helper'

class OrganisationTest < ActiveSupport::TestCase

  context "loading organisations" do
    setup do
      @organisation_attrs = [
        { "id" => "committee-on-climate-change",
          "name" => "Committee on Climate Change",
          "abbreviation" => "CCC"
        },
        { "id" => "competition-commission",
          "name" => "Competition Commission",
          "abbreviation" => "CC"
        }
      ]
    end

    should "return organisations from the need api" do
      GdsApi::NeedApi.any_instance.expects(:organisations)
        .returns(@organisation_attrs)
      organisations = Organisation.all

      assert_equal 2, organisations.size
      assert_equal(["committee-on-climate-change", "competition-commission"],
                   organisations.map(&:id))
      assert_equal(["Committee on Climate Change", "Competition Commission"],
                   organisations.map(&:name))
      assert_equal(["CCC", "CC"],
                   organisations.map(&:abbreviation))
    end

    should "only load the organisation results once" do
      GdsApi::NeedApi.any_instance.expects(:organisations).once

      5.times do
        Organisation.all
      end
    end

    should "show the organisation abbreviation and status" do
      organisation = Organisation.new(id: "id", name: "name", abbreviation: "abbr", govuk_status: 'live')
      assert_equal "name [abbr] (live)", organisation.name_with_abbreviation_and_status
    end

    should "not show the abbreviation if it is not present" do
      organisation = Organisation.new(id: "id", name: "name", govuk_status: 'exempt')
      assert_equal "name (exempt)", organisation.name_with_abbreviation_and_status
    end

    should "not show the abbreviation if it is the same as the name" do
      organisation = Organisation.new(id: "id", name: "name", abbreviation: "name", govuk_status: 'joining')
      assert_equal "name (joining)", organisation.name_with_abbreviation_and_status
    end
  end
end
