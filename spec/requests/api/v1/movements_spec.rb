require "rails_helper"

RSpec.describe "api stock movements", type: :request do
  let(:user) { create(:user) }
  let(:token) { create(:api_token, user: user).token }
  let(:item) { create(:item) }
  let(:warehouse) { create(:warehouse) }

  def movements
    response.parsed_body["movements"]
  end

  describe "POST /api/v1/receipts" do
    let(:body) do
      { item_id: item.id, warehouse_id: warehouse.id, lot_number: "L-1", expiry_date: "2027-03-31", quantity: 25 }
    end

    it "receives stock and returns the movement" do
      post_json api_v1_receipts_path, body, token: token

      expect(response).to have_http_status(:created)
      expect(movements.sole).to include(
        "kind" => "receipt", "quantity" => 25, "warehouse_id" => warehouse.id, "user_id" => user.id,
        "lot" => include("lot_number" => "L-1", "expiry_date" => "2027-03-31")
      )
    end

    it "answers 400 when a required field is missing" do
      post_json api_v1_receipts_path, body.except(:lot_number), token: token

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("parameter_missing")
    end

    it "answers 404 for an unknown warehouse" do
      post_json api_v1_receipts_path, body.merge(warehouse_id: 0), token: token

      expect(response).to have_http_status(:not_found)
    end

    it "answers 422 when the lot exists with another expiry date" do
      create(:lot, item: item, lot_number: "L-1", expiry_date: Date.new(2027, 1, 1))

      post_json api_v1_receipts_path, body, token: token

      expect(response).to have_http_status(:unprocessable_content)
      expect(error_code).to eq("expiry_mismatch")
    end

    it "answers 422 for an invalid quantity" do
      post_json api_v1_receipts_path, body.merge(quantity: -1), token: token

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq(
        "code" => "invalid_request", "message" => "Quantity must be a positive whole number"
      )
    end
  end

  describe "POST /api/v1/issues" do
    let(:sooner) { create(:lot, item: item, expiry_date: Date.current + 10) }
    let(:later) { create(:lot, item: item, expiry_date: Date.current + 90) }

    before do
      create(:stock_movement, lot: sooner, warehouse: warehouse, quantity: 3)
      create(:stock_movement, lot: later, warehouse: warehouse, quantity: 10)
    end

    it "returns one movement per lot the request was split across" do
      post_json api_v1_issues_path, { item_id: item.id, warehouse_id: warehouse.id, quantity: 5, reason: "order 7" }, token: token

      expect(response).to have_http_status(:created)
      expect(movements.map { |movement| [ movement.dig("lot", "id"), movement["quantity"] ] })
        .to eq([ [ sooner.id, -3 ], [ later.id, -2 ] ])
    end

    it "answers 422 with the available quantity when stock is short" do
      post_json api_v1_issues_path, { item_id: item.id, warehouse_id: warehouse.id, quantity: 20 }, token: token

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq(
        "code" => "insufficient_stock",
        "message" => "Requested 20 but only 13 available",
        "details" => { "requested" => 20, "available" => 13 }
      )
    end
  end

  describe "POST /api/v1/transfers" do
    let(:lot) { create(:lot, item: item) }
    let(:destination) { create(:warehouse) }

    before { create(:stock_movement, lot: lot, warehouse: warehouse, quantity: 8) }

    it "returns both legs of the transfer" do
      post_json api_v1_transfers_path,
        { lot_id: lot.id, from_warehouse_id: warehouse.id, to_warehouse_id: destination.id, quantity: 8 }, token: token

      expect(response).to have_http_status(:created)
      expect(movements.pluck("kind", "warehouse_id")).to eq([ [ "transfer_out", warehouse.id ], [ "transfer_in", destination.id ] ])
      expect(movements.pluck("transfer_id").uniq.size).to eq(1)
    end

    it "answers 422 when both warehouses are the same" do
      post_json api_v1_transfers_path,
        { lot_id: lot.id, from_warehouse_id: warehouse.id, to_warehouse_id: warehouse.id, quantity: 1 }, token: token

      expect(response).to have_http_status(:unprocessable_content)
      expect(error_code).to eq("same_warehouse")
    end
  end

  describe "POST /api/v1/adjustments" do
    let(:lot) { create(:lot, item: item) }

    it "records an adjustment with its reason" do
      post_json api_v1_adjustments_path,
        { lot_id: lot.id, warehouse_id: warehouse.id, quantity: 4, reason: "found in returns" }, token: token

      expect(response).to have_http_status(:created)
      expect(movements.sole).to include("kind" => "adjustment", "quantity" => 4, "reason" => "found in returns")
    end

    it "answers 422 with field errors when the reason is missing" do
      post_json api_v1_adjustments_path, { lot_id: lot.id, warehouse_id: warehouse.id, quantity: 4 }, token: token

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to include(
        "code" => "validation_failed", "details" => { "reason" => [ "can't be blank" ] }
      )
    end
  end

  it "requires authentication" do
    post api_v1_issues_path, params: { item_id: item.id }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
