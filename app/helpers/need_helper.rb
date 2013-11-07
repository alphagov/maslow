module NeedHelper
  def format_need_goal(goal)
    words = goal.split(" ")
    words.first[0] = words.first[0].upcase
    words.join(" ")
  end

  def format_field_value(value)
    value.present? ? value : "<em>blank</em>".html_safe
  end

  def format_field_name(name)
    name.titleize
  end

  def defaulted_criteria(criteria)
    unless criteria.nil? || criteria.empty?
      criteria
    else
      [""]
    end
  end
end
