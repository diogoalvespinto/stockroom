FactoryBot.define do
  factory :api_token do
    user
    name { "integration" }
  end
end
