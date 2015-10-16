module NeedHelper
  include ActiveSupport::Inflector
  include ActionView::Helpers::NumberHelper

  def breadcrumb_link_for(need)
    link_to breadcrumb_label_for(need), need_path(need)
  end

  def breadcrumb_label_for(need)
    "#{need.need_id}: #{format_need_goal(need.goal)}"
  end

  def format_need_goal(goal)
    return "" if goal.blank?

    words = goal.split(" ")
    words.first[0] = words.first[0].upcase
    words.join(" ")
  end

  def format_field_value(value)
    if value.nil? || value.to_s.strip == ""
      "<em>blank</em>".html_safe
    else
      value.to_s
    end
  end

  def format_field_name(name)
    name.titleize
  end

  # If no criteria present, insert a blank
  # one.
  def criteria_with_blank_value(criteria)
    criteria.present? ? criteria : [""]
  end

  def format_need_impact(impact)
    impact_key = impact.parameterize.underscore
    translated = t("needs.show.impact.#{impact_key}")

    "If GOV.UK didn't meet this need #{translated}."
  end

  def calculate_percentage(numerator, denominator)
    return unless numerator.present? && denominator.present?
    return if denominator == 0

    percent = numerator.to_f / denominator.to_f * 100.0

    # don't include the fractional part if the percentage is X.0%
    format = percent.modulo(1) < 0.1 ? "%.0f\%" : "%.1f\%"
    (format % percent)
  end

  def show_interactions_column?(need)
    [need.yearly_user_contacts, need.yearly_site_views, need.yearly_need_views, need.yearly_searches].select(&:present?).any?
  end

  def format_friendly_integer(number)
    if number >= 1000000
      "%.3g\m" % (number.to_f / 1000000)
    elsif number >= 1000
      "%.3g\k" % (number.to_f / 1000)
    else
      number.to_s
    end
  end

  def paginate_needs(needs)
    return unless needs.present? && needs.current_page.present? && needs.pages.present? && needs.page_size.present?

    Kaminari::Helpers::Paginator.new(
      self,
      current_page: needs.current_page,
      total_pages: needs.pages,
      per_page: needs.page_size,
      param_name: "page",
      remote: false
    ).to_s
  end

  def canonical_need_goal
    Need.find(@need.duplicate_of).goal
  end

  def format_decision_made(need)
    decision = []
    decision << need.status.description.capitalize
    decision << "Duplicate" if need.duplicate?
    decision.join(", ")
  end

  def feedback_for_page(artefact)
    path = URI(artefact.web_url).path
    Maslow.support_api.feedback_url path
  end

  def bookmark_icon(bookmarks = [], need_id)
    bookmarks.include?(need_id.to_i) ? 'glyphicon-star' : 'glyphicon-star-empty'
  end

  def status_label_class(status_description)
    case status_description
    when "valid" then "label-success"
    when "not valid" then "label-danger"
    when "valid with conditions" then "label-warning"
    else "label-info"
    end
  end
end
