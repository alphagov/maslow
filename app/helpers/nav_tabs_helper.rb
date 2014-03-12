module NavTabsHelper
  def nav_tabs_for(need)
    tabs = {
      "View" => need_path(need),
      "Edit" => edit_need_path(need),
      "Actions" => actions_need_path(need),
      "History & Notes" => revisions_need_path(need)
    }
    tabs.delete("Edit") if need.duplicate_of.present?
    tabs
  end
end
