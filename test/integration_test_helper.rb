require_relative 'test_helper'

require 'capybara/rails'
require 'gds_api/test_helpers/content_api'
require 'gds_api/test_helpers/need_api'

class ActionDispatch::IntegrationTest
  include Capybara::DSL
  include GdsApi::TestHelpers::ContentApi
  include GdsApi::TestHelpers::NeedApi

  def login_as(user)
    GDS::SSO.test_user = user
    Capybara.current_session.driver.browser.clear_cookies
  end

  def click_on_first(selector)
    first(:button, selector).click
  end

  def setup_need_api_responses(need_id, artefacts=[])
    json = File.read Rails.root.join("test", "fixtures", "needs", "#{need_id}.json")

    entire_need = JSON.parse(json)
    need_api_has_need(entire_need)

    basic_need = entire_need.slice("id", "role", "goal", "benefit", "organisation_ids", "organisations")
    need_api_has_needs([basic_need])

    content_api_has_artefacts_for_need_id(basic_need["id"], artefacts)
  end
end
