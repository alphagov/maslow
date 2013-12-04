require_relative '../test_helper'
require 'gds_api/test_helpers/need_api'

class OrganisationTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::NeedApi

  context "loading organisations" do
    setup do
      need_api_has_organisations(
        "committee-on-climate-change" => "Committee on Climate Change",
        "competition-commission" => "Competition Commission"
      )
    end

    should "return organisations from the need api" do
      organisations = Organisation.all

      assert_equal 2, organisations.size
      assert_equal ["committee-on-climate-change", "competition-commission"], organisations.map(&:id)
      assert_equal ["Committee on Climate Change", "Competition Commission"], organisations.map(&:name)
    end

    should "only load the organisation results once" do
      GdsApi::NeedApi.any_instance.expects(:organisations).once

      5.times do
        Organisation.all
      end
    end

    should "show the organisation abbreviation" do
      organisation = Organisation.new(id: "id", name: "name", abbreviation: "abbr")
      assert_equal "name [abbr]", organisation.display_name
    end

    should "not show the abbreviation if it is not present" do
      organisation = Organisation.new(id: "id", name: "name")
      assert_equal "name", organisation.display_name
    end

    should "not show the abbreviation if it is the same as the name" do
      organisation = Organisation.new(id: "id", name: "name", abbreviation: "name")
      assert_equal "name", organisation.display_name
    end
  end
end
