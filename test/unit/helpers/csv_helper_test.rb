require_relative '../../test_helper'

class CsvHelperTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include CsvHelper
  default_url_options[:host] = "link"

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
      assert_equal "Maslow URL,As a,I need to,So that\n", csv_from_needs([])
    end

    should "return a single row if only one need id given" do
      url = need_url(@need_1["id"])
      expected = "Maslow URL,As a,I need to,So that\n#{url},Foo,Bar,Baz\n"

      assert_equal expected,
                   csv_from_needs([Need.new(@need_1,true)])
    end

    should "return rows with acceptance criteria, if present" do
      url_1 = need_url(@need_1["id"])
      url_2 = need_url(@need_2["id"])
      expected = """Maslow URL,As a,I need to,So that,Met when criteria 1,Met when criteria 2
#{url_1},Foo,Bar,Baz
#{url_2},Foo,Bar,Baz,a,b\n"""

      assert_equal expected,
                   csv_from_needs([Need.new(@need_1,true),
                                   Need.new(@need_2,true)])
    end
  end
end
