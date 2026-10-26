FactoryBot.define do
  factory :idempotency_key do
    user
    sequence(:key) { |n| "key-#{n}" }
    request_digest { OpenSSL::Digest::SHA256.hexdigest("POST /api/v1/issues") }
    response_status { 201 }
    response_body { "{}" }
  end
end
