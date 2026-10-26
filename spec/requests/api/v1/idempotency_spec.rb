require "rails_helper"

RSpec.describe "api idempotency", type: :request do
  let(:user) { create(:user) }
  let(:token) { create(:api_token, user: user).token }
  let(:warehouse) { create(:warehouse) }
  let(:lot) { create(:lot) }
  let(:body) { { item_id: lot.item_id, warehouse_id: warehouse.id, quantity: 4 } }

  before { create(:stock_movement, lot: lot, warehouse: warehouse, quantity: 10) }

  def issue(body = self.body, token: self.token, key: "issue-1")
    post_json api_v1_issues_path, body, token: token, idempotency_key: key
  end

  it "replays the first response when a request is retried with the same key" do
    issue
    first_response = response.body

    expect { issue }.not_to change(StockMovement, :count)

    expect(response).to have_http_status(:created)
    expect(response.body).to eq(first_response)
    expect(response.headers["Idempotent-Replayed"]).to eq("true")
  end

  it "treats a different key as a different request" do
    issue(key: "issue-1")

    expect { issue(key: "issue-2") }.to change(StockMovement, :count).by(1)
    expect(response.headers["Idempotent-Replayed"]).to be_nil
  end

  it "rejects a key reused with a different request body" do
    issue
    issue(body.merge(quantity: 5))

    expect(response).to have_http_status(:unprocessable_content)
    expect(error_code).to eq("idempotency_key_reused")
  end

  it "keeps keys separate per user" do
    issue

    expect { issue(token: create(:api_token).token) }.to change(StockMovement, :count).by(1)
  end

  it "does not remember a failed request, so it can be retried once stock arrives" do
    issue(body.merge(quantity: 50))
    expect(response).to have_http_status(:unprocessable_content)

    create(:stock_movement, lot: lot, warehouse: warehouse, quantity: 100)
    issue(body.merge(quantity: 50))

    expect(response).to have_http_status(:created)
  end

  [ nil, "", "x" * 256 ].each do |key|
    it "rejects an Idempotency-Key of #{key.to_s.length} characters" do
      post api_v1_issues_path, params: body, headers: api_headers(token, idempotency_key: key), as: :json

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_idempotency_key")
    end
  end
end
