require "rails_helper"

RSpec.describe LotSerializer do
  it "renders the expiry date as an iso 8601 date" do
    lot = build_stubbed(:lot, lot_number: "L-7", expiry_date: Date.new(2027, 1, 31))

    expect(described_class.new(lot).as_json).to eq(
      id: lot.id, item_id: lot.item_id, lot_number: "L-7", expiry_date: "2027-01-31"
    )
  end

  it "renders a missing expiry date as null" do
    expect(described_class.new(build_stubbed(:lot, :without_expiry)).as_json[:expiry_date]).to be_nil
  end
end
