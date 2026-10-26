module ApiHelpers
  def api_headers(token, idempotency_key: nil)
    { "Authorization" => "Bearer #{token}", "Idempotency-Key" => idempotency_key }.compact
  end

  def post_json(path, body, token:, idempotency_key: SecureRandom.uuid)
    post path, params: body, headers: api_headers(token, idempotency_key: idempotency_key), as: :json
  end

  def error_code
    response.parsed_body.dig("error", "code")
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
