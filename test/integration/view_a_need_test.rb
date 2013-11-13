require_relative '../integration_test_helper'

class ViewANeedTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
    need_api_has_organisations(
      "driver-vehicle-licensing-agency" => "Driver and Vehicle Licensing Agency",
      "driving-standards-agency" => "Driving Standards Agency",
    )
  end

  context "given a need which exists" do
    setup do
      setup_need_api_responses(101350)
    end

    should "show basic information about the need" do
      visit "/needs"
      click_on "101350"

      within ".need-breadcrumb" do
        assert page.has_link?("All needs", href: "/needs")
        assert page.has_content?("Book a driving test")
      end

      within "#single-need" do
        within "header" do
          within ".organisations" do
            assert page.has_content?("Driver and Vehicle Licensing Agency, Driving Standards Agency")
          end

          assert page.has_content?("Book a driving test")
          assert page.has_link?("Edit need", href: "/needs/101350/edit")
        end

      end
    end
  end

end
