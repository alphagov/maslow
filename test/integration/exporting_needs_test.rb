require_relative '../integration_test_helper'

class ExportingNeedsTest < ActionDispatch::IntegrationTest

  def filter_needs
    visit "/needs"
    select("Department for Education [DfE]", from: "Filter needs by organisation:")
    click_on_first_button("Filter")
  end

  def csv_file(n)
    File.read Rails.root.join("test", "fixtures", "needs", "needs-#{n}.csv")
  end

  setup do
    login_as_stub_user
  end

  context "exporting a filtered list of needs" do
    context "no needs after filtering" do
      setup do
        need_api_has_organisations(
          "department-for-education" => { "name" => "Department for Education",
                                          "abbreviation" => "DfE"
                                        }
        )
        need_api_has_needs([])
        need_api_has_needs_for_organisation("department-for-education", [])
      end

      should "return a csv with only headers" do
        filter_needs

        click_on("Export as CSV")

        assert_equal "text/csv; charset=utf-8", page.response_headers["Content-Type"]
        assert_equal csv_file(1), page.source
      end
    end

    context "one need after filtering" do
      setup do
        need_api_has_organisations(
          "department-for-education" => { "name" => "Department for Education",
                                          "abbreviation" => "DfE"
                                        }
        )
        @needs = [
          {
            "id" => "100001",
            "role" => "Foo",
            "goal" => "Bar",
            "benefit" => "Baz",
            "organisations" => []
          }
        ]
        need_api_has_needs(@needs)
        need_api_has_needs_for_organisation("department-for-education", @needs)
      end

      should "return a csv of the filtered needs" do
        filter_needs

        need_api_has_need(@needs[0])

        click_on("Export as CSV")

        assert_equal "text/csv; charset=utf-8", page.response_headers["Content-Type"]
        assert_equal(csv_file(2),page.source)
      end
    end

    context "several needs with met when criteria" do
      setup do
        need_api_has_organisations(
          "department-for-education" => { "name" => "Department for Education",
                                          "abbreviation" => "DfE"
                                        }
        )
        @needs = [
          {
            "id" => "100001",
            "role" => "Foo",
            "goal" => "Bar",
            "benefit" => "Baz",
            "organisations" => []
          },
          {
            "id" => "100002",
            "role" => "Foo",
            "goal" => "Bar",
            "benefit" => "Baz",
            "organisations" => [],
            "met_when" => ["a","b"]
          }
        ]
        need_api_has_needs(@needs)
        need_api_has_needs_for_organisation("department-for-education", @needs)
      end

      should "return a csv of the filtered needs" do
        filter_needs

        need_api_has_need(@needs[0])
        need_api_has_need(@needs[1])

        click_on("Export as CSV")

        assert_equal "text/csv; charset=utf-8", page.response_headers["Content-Type"]
        assert_equal(csv_file(3), page.source)
      end
    end
  end
end
