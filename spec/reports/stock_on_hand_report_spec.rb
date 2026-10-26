require "rails_helper"

RSpec.describe StockOnHandReport do
  let(:lisbon) { create(:warehouse, code: "LIS") }
  let(:porto) { create(:warehouse, code: "OPO") }
  let(:gloves) { create(:item, sku: "GLV-1") }
  let(:masks) { create(:item, sku: "MSK-1") }

  def stock(warehouse, lot, quantity)
    create(:stock_movement, warehouse: warehouse, lot: lot, quantity: quantity)
    lot
  end

  def summary(rows)
    rows.map { |row| [ row.warehouse.code, row.item.sku, row.lot.lot_number, row.quantity ] }
  end

  it "lists the balance of every lot in every warehouse, sorted by warehouse, item and expiry" do
    stock(porto, create(:lot, item: gloves, lot_number: "G-1"), 2)
    stock(lisbon, create(:lot, item: masks, lot_number: "M-1"), 7)
    stock(lisbon, create(:lot, item: gloves, lot_number: "G-UNDATED", expiry_date: nil), 1)
    stock(lisbon, create(:lot, item: gloves, lot_number: "G-2", expiry_date: Date.current + 5), 4)

    expect(summary(described_class.new.rows)).to eq([
      [ "LIS", "GLV-1", "G-2", 4 ],
      [ "LIS", "GLV-1", "G-UNDATED", 1 ],
      [ "LIS", "MSK-1", "M-1", 7 ],
      [ "OPO", "GLV-1", "G-1", 2 ]
    ])
  end

  it "leaves out lots whose stock has been used up" do
    lot = stock(lisbon, create(:lot, item: gloves), 3)
    create(:stock_movement, :issue, warehouse: lisbon, lot: lot, quantity: -3)

    expect(described_class.new.rows).to be_empty
  end

  it "can be limited to one warehouse" do
    stock(lisbon, create(:lot, item: gloves, lot_number: "G-1"), 2)
    stock(porto, create(:lot, item: gloves, lot_number: "G-2"), 2)

    expect(summary(described_class.new(warehouse: porto).rows)).to eq([ [ "OPO", "GLV-1", "G-2", 2 ] ])
  end

  it "can be limited to some lots" do
    wanted = stock(lisbon, create(:lot, item: gloves, lot_number: "G-1"), 2)
    stock(lisbon, create(:lot, item: gloves, lot_number: "G-2"), 2)

    expect(summary(described_class.new(lots: Lot.where(id: wanted)).rows)).to eq([ [ "LIS", "GLV-1", "G-1", 2 ] ])
  end
end
