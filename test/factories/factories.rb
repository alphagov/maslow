FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Winston #{n}"}
    permissions { ["signin"] }

    factory :editor do
      permissions { ["signin", "editor"] }
    end

    factory :admin do
      permissions { ["signin", "editor", "admin"] }
    end
  end
end
