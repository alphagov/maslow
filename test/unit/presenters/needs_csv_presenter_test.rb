require_relative "../../test_helper"

class NeedsCsvPresenterTest < ActiveSupport::TestCase
  def base_url
    "http://www.example.com/needs"
  end

  def csv_file(number)
    File.read(Rails.root.join("test", "fixtures", "needs", "needs-#{number}.csv"))
  end

  context "csv_from_need_ids" do
    setup do
      @need1 = {
        "need_id" => "100001",
        "role" => "Foo",
        "goal" => "Bar",
        "benefit" => "Baz",
      }
      @need2 = {
        "need_id" => "100002",
        "role" => "Foo",
        "goal" => "Bar",
        "benefit" => "Baz",
        "met_when" => %w(a b),
      }
    end

    should "return only headers if no ids given" do
      csv = NeedsCsvPresenter.new(base_url, []).to_csv
      assert_equal csv_file(1), csv
    end

    should "return a single row if only one need id given" do
      csv = NeedsCsvPresenter.new(base_url,
                                  [Need.new(@need1)]).to_csv
      assert_equal csv_file(2), csv
    end

    should "return rows with acceptance criteria, if present" do
      csv = NeedsCsvPresenter.new(base_url,
                                  [Need.new(@need1),
                                   Need.new(@need2)]).to_csv
      assert_equal csv_file(3), csv
    end
  end
end
