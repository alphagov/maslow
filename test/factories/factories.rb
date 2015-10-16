FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Winston #{n}"}
    permissions { ["signin"] }

    factory :editor do
      permissions { %w(signin editor) }
    end

    factory :admin do
      permissions { %w(signin editor admin) }
    end
  end
end
