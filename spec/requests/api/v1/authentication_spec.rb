require "rails_helper"

RSpec.describe "api authentication", type: :request do
  let(:api_token) { create(:api_token) }

  it "accepts a valid bearer token" do
    get api_v1_warehouses_path, headers: api_headers(api_token.token)

    expect(response).to have_http_status(:ok)
  end

  it "rejects a request without a token" do
    get api_v1_warehouses_path

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["WWW-Authenticate"]).to eq('Bearer realm="Stockroom"')
    expect(response.parsed_body).to eq(
      "error" => { "code" => "unauthorized", "message" => "A valid API token is required" }
    )
  end

  it "rejects an unknown token" do
    get api_v1_warehouses_path, headers: api_headers("not-a-token")

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a revoked token" do
    token = api_token.token
    api_token.destroy

    get api_v1_warehouses_path, headers: api_headers(token)

    expect(response).to have_http_status(:unauthorized)
  end

  it "answers unknown api paths with the json error format" do
    get "/api/v1/nowhere", headers: api_headers(api_token.token)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "message")).to eq("No route matches GET /api/v1/nowhere")
  end
end
