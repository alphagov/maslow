require_relative '../../test_helper'

class NavTabsHelperTest < ActiveSupport::TestCase
  include NavTabsHelper
  include Rails.application.routes.url_helpers

  setup do
    @need = Need.new({"id" => 100001}, true)
  end

  should "include all possible tabs" do
    assert_equal ["View", "Edit", "Actions", "History & Notes"],
                 tab_names_on_needs_page_for(@need)
  end

  should "not include an Edit link if the need is duplicated" do
    @need.duplicate_of = 12345
    refute tab_names_on_needs_page_for(@need).include?("Edit")
  end

  private
  def tab_names_on_needs_page_for(need)
    nav_tabs_for(need).map(&:first)
  end
end
