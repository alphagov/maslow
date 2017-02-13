require_relative '../integration_test_helper'

class ExportingNeedsTest < ActionDispatch::IntegrationTest
  setup do
    login_as_stub_user

    links_url = %r{\A#{Plek.find('publishing-api')}/v2/links/}
    stub_request(:get, links_url).to_return(
      body: {
        links: {
          organisations: []
        }
      }.to_json
    )
    linkables_url = %r{\A#{Plek.find('publishing-api')}/v2/linkables}
    stub_request(:get, linkables_url).to_return(
      body: {}.to_json
    )
  end

  context "no needs to export" do
    setup do
      publishing_api_has_content(
        [],
        Need.default_options.merge(
          per_page: 50
        )
      )
    end

    should "return a csv with only headers" do
      visit "/needs"

      click_on("Export as CSV")

      assert_equal "text/csv; charset=utf-8", page.response_headers["Content-Type"]
      assert_equal(page.source.lines.count, 1)
    end
  end

  context "one need" do
    setup do
      publishing_api_has_content(
        [create(:need_content_item)],
        Need.default_options.merge(
          per_page: 50
        )
      )
    end

    should "return a csv of the needs" do
      visit "/needs"

      click_on("Export as CSV")

      assert_equal "text/csv; charset=utf-8", page.response_headers["Content-Type"]
      assert_equal(page.source.lines.count, 2)
    end
  end

  context "several needs with met when criteria" do
    setup do
      publishing_api_has_content(
        create_list(:need_content_item, 3),
        Need.default_options.merge(
          per_page: 50
        )
      )
    end

    should "return a csv of the needs" do
      visit "/needs"

      click_on("Export as CSV")

      assert_equal "text/csv; charset=utf-8", page.response_headers["Content-Type"]
      assert_equal(page.source.lines.count, 4)
    end
  end
end
