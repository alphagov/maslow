require 'csv'

module CsvHelper
  def csv_from_needs(needs = [])
    length = longest_acceptance_criteria(needs)
    generate_csv(csv_fields(length), needs)
  end

  private

  def generate_csv(fields, values)
    CSV.generate do |csv|
      csv << fields
      values.each do |need|
        csv << row_values(need)
      end
    end
  end

  def row_values(need)
    [need_url(need),
     need.role,
     need.goal,
     need.benefit] + need.met_when.to_a
  end

  def csv_fields(length)
    ["Maslow URL", "As a", "I need to", "So that"] + acceptance_field_names(length)
  end

  def acceptance_field_names(length)
    (1..length).map {|n| "Met when criteria #{n}"}
  end

  def longest_acceptance_criteria(needs)
    needs.map(&:met_when)
         .sort_by{|x| x.length}.reverse
         .first.try(:size) || 0
  end
end
