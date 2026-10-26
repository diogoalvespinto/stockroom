require "rails_helper"

RSpec.describe "api items and lots", type: :request do
  let(:token) { create(:api_token).token }

  describe "GET /api/v1/items" do
    it "lists the items ordered by sku" do
      gloves = create(:item, sku: "GLV-1", name: "Gloves", unit_of_measure: "box", reorder_level: 20)
      create(:item, sku: "MSK-1")

      get api_v1_items_path, headers: api_headers(token)

      expect(response.parsed_body["items"].pluck("sku")).to eq(%w[GLV-1 MSK-1])
      expect(response.parsed_body["items"].first).to eq(
        "id" => gloves.id, "sku" => "GLV-1", "name" => "Gloves", "unit_of_measure" => "box", "reorder_level" => 20
      )
    end
  end

  describe "GET /api/v1/items/:item_id/lots" do
    let(:item) { create(:item) }

    it "lists the item's lots in fefo order" do
      later = create(:lot, item: item, expiry_date: Date.new(2027, 5, 1))
      sooner = create(:lot, item: item, expiry_date: Date.new(2027, 1, 1))
      create(:lot)

      get api_v1_item_lots_path(item), headers: api_headers(token)

      expect(response.parsed_body["lots"].pluck("id")).to eq([ sooner.id, later.id ])
    end

    it "answers 404 for an unknown item" do
      get api_v1_item_lots_path(item_id: 0), headers: api_headers(token)

      expect(response).to have_http_status(:not_found)
      expect(error_code).to eq("not_found")
    end
  end
end
