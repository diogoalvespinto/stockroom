require "rails_helper"

RSpec.describe ReceiptForm do
  let(:user) { create(:user) }
  let(:item) { create(:item, sku: "GLV-1", unit_of_measure: "box") }
  let(:warehouse) { create(:warehouse, code: "LIS") }

  def form(**overrides)
    described_class.new(
      { item_id: item.id, warehouse_id: warehouse.id, lot_number: "G-1", expiry_date: "2027-03-31", quantity: "12" }
        .merge(overrides)
    )
  end

  it "uses receipt as its parameter key" do
    expect(described_class.model_name.param_key).to eq("receipt")
  end

  it "receives the stock and summarises what happened" do
    receipt = form

    expect(receipt.save(user: user)).to be(true)
    expect(receipt.movement).to be_persisted
    expect(receipt.summary).to eq("Received 12 box of GLV-1 into LIS (lot G-1)")
  end

  it "reports missing fields without calling the service" do
    receipt = described_class.new

    expect(receipt.save(user: user)).to be(false)
    expect(receipt.errors.full_messages).to contain_exactly(
      "Item can't be blank", "Warehouse can't be blank", "Lot number can't be blank", "Quantity can't be blank"
    )
  end

  it "turns a refused receipt into an error message" do
    receipt = form(quantity: "0")

    expect(receipt.save(user: user)).to be(false)
    expect(receipt.errors.full_messages).to eq([ "Quantity must be a positive whole number" ])
  end
end
