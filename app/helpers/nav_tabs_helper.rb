module NavTabsHelper
  def nav_tabs_for(need)
    tabs = []
    tabs << ["View", need_path(need)]
    tabs << ["Edit", edit_need_path(need)] if !need.duplicate? && current_user.can?(:update, Need)
    tabs << ["Actions", actions_need_path(need)] if current_user.can?(:perform_actions_on, Need)
    tabs << ["History & Notes", revisions_need_path(need)]
    tabs
  end
end
