module ApiHelpers
  def api_headers(token, idempotency_key: nil)
    { "Authorization" => "Bearer #{token}", "Idempotency-Key" => idempotency_key }.compact
  end

  def error_code
    response.parsed_body.dig("error", "code")
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
