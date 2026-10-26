FactoryBot.define do
  factory :lot do
    item
    sequence(:lot_number) { |n| "LOT-#{n}" }
    expiry_date { 1.year.from_now.to_date }

    trait :expired do
      expiry_date { Date.yesterday }
    end

    trait :without_expiry do
      expiry_date { nil }
    end
  end
end
