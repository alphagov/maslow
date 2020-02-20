require_relative "../../test_helper"
require_relative "../../../app/helpers/nav_tabs_helper"

class NavTabsHelperTest < ActiveSupport::TestCase
  include NavTabsHelper
  include Rails.application.routes.url_helpers
  attr_reader :current_user

  setup do
    @need = Need.new
  end

  context "for an editor" do
    setup do
      @current_user = stub(user: nil)
      @current_user.stubs(:can?).with(:update, Need).returns(true)
      @current_user.stubs(:can?).with(:perform_actions_on, Need).returns(true)
    end

    should "include all possible tabs" do
      assert_equal ["View", "Edit", "Actions", "History & Notes"],
                   tab_names_on_needs_page_for(@need)
    end

    should "not include an Edit link if the need is unpublished" do
      @need.publication_state = "unpublished"
      assert_not tab_names_on_needs_page_for(@need).include?("Edit")
    end
  end

  context "for a viewer" do
    setup do
      @current_user = stub(can?: false)
    end

    should "not include Edit or Actions links" do
      assert_equal ["View", "History & Notes"],
                   tab_names_on_needs_page_for(@need)
    end
  end

private

  def tab_names_on_needs_page_for(need)
    nav_tabs_for(need).map(&:first)
  end
end
