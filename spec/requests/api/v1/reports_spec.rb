require "rails_helper"

RSpec.describe "api stock and reports", type: :request do
  let(:token) { create(:api_token).token }
  let(:warehouse) { create(:warehouse) }
  let(:item) { create(:item, reorder_level: 50) }

  def stock(expiry_date:, quantity:, warehouse: self.warehouse)
    create(:lot, item: item, expiry_date: expiry_date).tap do |lot|
      create(:stock_movement, lot: lot, warehouse: warehouse, quantity: quantity)
    end
  end

  describe "GET /api/v1/stock" do
    it "lists the stock on hand per lot, optionally for one warehouse" do
      lot = stock(expiry_date: Date.current + 10, quantity: 7)
      stock(expiry_date: Date.current + 10, quantity: 3, warehouse: create(:warehouse))

      get api_v1_stock_path(warehouse_id: warehouse.id), headers: api_headers(token)

      expect(response.parsed_body["stock"]).to eq([
        { "warehouse_id" => warehouse.id, "item_id" => item.id, "quantity" => 7,
          "lot" => { "id" => lot.id, "item_id" => item.id, "lot_number" => lot.lot_number, "expiry_date" => lot.expiry_date.iso8601 } }
      ])
    end
  end

  describe "GET /api/v1/reports/expiring_lots" do
    it "lists lots expiring within the requested number of days" do
      soon = stock(expiry_date: Date.current + 3, quantity: 2)
      stock(expiry_date: Date.current + 20, quantity: 2)

      get api_v1_reports_expiring_lots_path(days: 7), headers: api_headers(token)

      expect(response.parsed_body).to include("within_days" => 7)
      expect(response.parsed_body["lots"].map { |row| [ row.dig("lot", "id"), row["days_left"] ] }).to eq([ [ soon.id, 3 ] ])
    end

    it "defaults to 30 days" do
      get api_v1_reports_expiring_lots_path, headers: api_headers(token)

      expect(response.parsed_body["within_days"]).to eq(30)
    end

    it "rejects a window that is not between 1 and 365 days" do
      get api_v1_reports_expiring_lots_path(days: "forever"), headers: api_headers(token)

      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("invalid_parameter")
    end
  end

  describe "GET /api/v1/reports/below_reorder_level" do
    it "lists items short of their reorder level with the shortfall" do
      stock(expiry_date: Date.current + 10, quantity: 20)

      get api_v1_reports_below_reorder_level_path, headers: api_headers(token)

      expect(response.parsed_body["items"]).to eq([
        { "item" => ItemSerializer.new(item).as_json.stringify_keys, "usable_quantity" => 20, "shortfall" => 30 }
      ])
    end
  end
end
