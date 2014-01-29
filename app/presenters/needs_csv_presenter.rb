require 'csv'

class NeedsCsvPresenter
  def initialize(base_url, needs = [])
    @base_url = base_url
    @needs = needs
    @criteria_length = longest_criteria(needs)
  end

  def to_csv
    generate_csv(csv_fields(@criteria_length), @needs)
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
    [@base_url+"/#{need.need_id}",
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

  def longest_criteria(needs)
    needs.map(&:met_when)
         .max_by(&:length)
         .try(:size) || 0
  end

end
