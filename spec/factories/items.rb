FactoryBot.define do
  factory :item do
    sequence(:sku) { |n| "SKU-#{n}" }
    name { Faker::Commerce.product_name }
    unit_of_measure { "each" }
    reorder_level { 0 }
  end
end
