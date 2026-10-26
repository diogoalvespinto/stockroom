FactoryBot.define do
  factory :warehouse do
    name { "#{Faker::Address.city} warehouse" }
    sequence(:code) { |n| "WH-#{n}" }
  end
end
