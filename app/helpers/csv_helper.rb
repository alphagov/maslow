require 'csv'

module CsvHelper
  def csv_from_need_ids(need_ids)
    needs = need_ids.map {|id| Need.find(id)}
    length = longest_acceptance_criteria(needs)
    generate_csv(csv_fields(length), needs)
  end

  private

  def generate_csv(fields, values)
    CSV.generate do |csv|
      csv << fields
      values.each do |need|
        csv << [need_url(need),
                need.role,
                need.goal,
                need.benefit] + need.met_when.to_a
      end
    end
  end

  def csv_fields(length)
    ["Link", "Role", "Goal", "Benefit"] + acceptance_field_names(length)
  end

  def acceptance_field_names(length)
    (1..length).map {|n| "Acceptance Criteria #{n}"}
  end

  def longest_acceptance_criteria(needs)
    needs.map(&:met_when)
         .sort_by{|x| x.length}.reverse
         .first.try(:size) || 0
  end
end
