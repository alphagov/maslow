require_relative "test_helper"

require "capybara/rails"
require "gds_api/test_helpers/publishing_api"

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include GdsApi::TestHelpers::PublishingApi

  def login_as(user)
    GDS::SSO.test_user = user
    Capybara.current_session.driver.browser.clear_cookies
  end

  def click_on_first_button(selector)
    first(:button, selector).click
  end
end
