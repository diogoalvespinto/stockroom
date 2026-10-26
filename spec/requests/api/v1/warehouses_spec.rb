require "rails_helper"

RSpec.describe "api warehouses", type: :request do
  let(:token) { create(:api_token).token }

  describe "GET /api/v1/warehouses" do
    it "lists the warehouses ordered by code" do
      north = create(:warehouse, code: "NORTH", name: "North depot")
      east = create(:warehouse, code: "EAST", name: "East depot")

      get api_v1_warehouses_path, headers: api_headers(token)

      expect(response.parsed_body["warehouses"]).to eq([
        { "id" => east.id, "code" => "EAST", "name" => "East depot" },
        { "id" => north.id, "code" => "NORTH", "name" => "North depot" }
      ])
    end
  end
end
