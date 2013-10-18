require_relative 'test_helper'
require 'capybara/rails'

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  def login_as(user)
    GDS::SSO.test_user = user
    Capybara.current_session.driver.browser.clear_cookies
  end

  def click_on_first(selector)
    first(:button, selector).click
  end
end
