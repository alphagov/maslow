module NeedHelper
  def format_need_goal(goal)
    words = goal.split(" ")
    words.first[0] = words.first[0].upcase
    words.join(" ")
  end
end
