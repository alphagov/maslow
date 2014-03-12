module NavTabsHelper
  def nav_tabs_for(need)
    tabs = {
      "View" => need_path(need),
      "Actions" => actions_need_path(need),
      "History & Notes" => revisions_need_path(need)
    }
    tabs["Edit"] = edit_need_path(need) unless need.duplicate?
    tabs
  end
end
