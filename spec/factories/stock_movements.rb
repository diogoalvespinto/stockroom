FactoryBot.define do
  factory :stock_movement do
    lot
    warehouse
    user
    kind { :receipt }
    quantity { 10 }

    trait :issue do
      kind { :issue }
      quantity { -1 }
    end

    trait :transfer_out do
      kind { :transfer_out }
      quantity { -1 }
    end

    trait :transfer_in do
      kind { :transfer_in }
      quantity { 1 }
    end

    trait :adjustment do
      kind { :adjustment }
      quantity { -1 }
      reason { "damaged in storage" }
    end
  end
end
