require_relative '../../test_helper'

class CsvHelperTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include CsvHelper
  default_url_options[:host] = "www.example.com"

  def csv_file(n)
    File.read(Rails.root.join("test", "fixtures", "needs", "needs-#{n}.csv"))[0...-1]
  end

  context "csv_from_need_ids" do
    setup do
      @need_1 = {
        "id" => "100001",
        "role" => "Foo",
        "goal" => "Bar",
        "benefit" => "Baz"
      }
      @need_2 = {
        "id" => "100002",
        "role" => "Foo",
        "goal" => "Bar",
        "benefit" => "Baz",
        "met_when" => ["a","b"]
      }
    end

    should "return only headers if no ids given" do
      assert_equal csv_file(1), csv_from_needs([])
    end

    should "return a single row if only one need id given" do
      assert_equal csv_file(2),
                   csv_from_needs([Need.new(@need_1,true)])
    end

    should "return rows with acceptance criteria, if present" do
      assert_equal csv_file(3),
                   csv_from_needs([Need.new(@need_1,true),
                                   Need.new(@need_2,true)])
    end
  end
end
