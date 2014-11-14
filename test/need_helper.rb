module NeedHelper
  def minimal_example_need(options = {})
    {
      "id" => "10001",
      "role" => "parent",
      "goal" => "apply for a primary school place",
      "benefit" => "my child can start school",
    }.merge(options)
  end

  def example_need(options = {})
    {
      "id" => "10001",
      "role" => "parent",
      "goal" => "apply for a primary school place",
      "benefit" => "my child can start school",
      "organisation_ids" => ["department-for-education"],
      "organisations" => [
        {
          "id" => "department-for-education",
          "name" => "Department for Education",
        }
      ],
      "applies_to_all_organisations" => false,
      "justifications" => [
        "it's something only government does",
        "the government is legally obliged to provide it"
      ],
      "impact" => "Has serious consequences for the day-to-day lives of your users",
      "met_when" => [
        "The user applies for a school place"
      ],
      "duplicate_of" => nil,
    }.merge(options)
  end
end
