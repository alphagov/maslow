module NavTabsHelper
  def nav_tabs_for(need)
    tabs = []
    tabs << [ "View", need_path(need) ]
    tabs << [ "Edit", edit_need_path(need) ] unless need.duplicate?
    tabs << [ "Actions", actions_need_path(need) ]
    tabs << [ "History & Notes", revisions_need_path(need) ]
    tabs
  end
end
