require_relative '../integration_test_helper'

class ViewANeedTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
    need_api_has_organisations(
      "driver-vehicle-licensing-agency" => "Driver and Vehicle Licensing Agency"
    )
  end

  context "given a need which exists" do
    setup do
      setup_need_api_responses(101350)
    end

    should "show basic information about the need" do
      visit "/needs"
      click_on "101350"

      assert page.has_content?("Book a driving test")
      assert page.has_content?("As a user I need to book a driving test so that I can get my driving licence")

      assert page.has_link?("Edit this need", href: "/needs/101350/edit")
    end
  end

end
