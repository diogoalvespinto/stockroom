require "rails_helper"

RSpec.describe BelowReorderLevelReport do
  let(:today) { Date.new(2026, 10, 26) }

  def stock(item, quantity, expiry_date: today + 30, warehouse: create(:warehouse))
    create(:stock_movement, warehouse: warehouse, quantity: quantity, lot: create(:lot, item: item, expiry_date: expiry_date))
  end

  def summary
    described_class.new(on: today).rows.map { |row| [ row.item.sku, row.usable_quantity, row.shortfall ] }
  end

  it "lists items whose usable stock across warehouses is below the reorder level, biggest shortfall first" do
    gloves = create(:item, sku: "GLV-1", reorder_level: 50)
    stock(gloves, 20)
    stock(gloves, 10)
    masks = create(:item, sku: "MSK-1", reorder_level: 10)
    stock(masks, 9)

    expect(summary).to eq([ [ "GLV-1", 30, 20 ], [ "MSK-1", 9, 1 ] ])
  end

  it "does not count expired stock" do
    gloves = create(:item, sku: "GLV-1", reorder_level: 10)
    stock(gloves, 100, expiry_date: today - 1)
    stock(gloves, 4, expiry_date: nil)

    expect(summary).to eq([ [ "GLV-1", 4, 6 ] ])
  end

  it "includes items with no stock at all" do
    create(:item, sku: "GLV-1", reorder_level: 5)

    expect(summary).to eq([ [ "GLV-1", 0, 5 ] ])
  end

  it "leaves out items at their reorder level and items without one" do
    at_level = create(:item, reorder_level: 10)
    stock(at_level, 10)
    create(:item, reorder_level: 0)

    expect(summary).to be_empty
  end
end
