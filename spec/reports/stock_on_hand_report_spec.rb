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

  describe "#page" do
    context "with three lots in stock" do
      before do
        (1..3).each { |n| stock(lisbon, create(:lot, item: gloves, lot_number: "G-#{n}", expiry_date: Date.current + n), 1) }
      end

      it "returns the first rows and counts the pages" do
        result = described_class.new.page(1, per: 2)

        expect(summary(result.rows)).to eq([ [ "LIS", "GLV-1", "G-1", 1 ], [ "LIS", "GLV-1", "G-2", 1 ] ])
        expect(result.total_pages).to eq(2)
        expect(result).not_to be_last
      end

      it "returns the following rows on the next page" do
        result = described_class.new.page(2, per: 2)

        expect(summary(result.rows)).to eq([ [ "LIS", "GLV-1", "G-3", 1 ] ])
        expect(result).to be_last
      end

      it "still counts the pages when asked for one past the last" do
        result = described_class.new.page(5, per: 2)

        expect(result.rows).to be_empty
        expect(result.total_pages).to eq(2)
      end
    end

    it "never repeats or skips a lot across pages when lots tie on every sort key" do
      tied = Array.new(20) { stock(lisbon, create(:lot, item: gloves, expiry_date: Date.current + 9), 1) }

      paged = (1..7).flat_map { |number| described_class.new.page(number, per: 3).rows.map(&:lot) }

      expect(paged).to eq(tied)
    end

    it "has no pages without stock" do
      result = described_class.new.page(1)

      expect(result.rows).to be_empty
      expect(result.total_pages).to eq(0)
    end
  end

  describe "page window" do
    def window(number, total_pages)
      StockOnHandReport::Page.new(rows: [], number: number, total_pages: total_pages).window
    end

    it "shows the first and last pages and three on each side of the current one" do
      expect(window(15, 300)).to eq([ 1, :gap, 12, 13, 14, 15, 16, 17, 18, :gap, 300 ])
    end

    it "leaves out the gap next to the first or last page" do
      expect(window(2, 300)).to eq([ 1, 2, 3, 4, 5, :gap, 300 ])
      expect(window(299, 300)).to eq([ 1, :gap, 296, 297, 298, 299, 300 ])
    end

    it "shows a single hidden page instead of a gap" do
      expect(window(6, 300)).to eq([ 1, 2, 3, 4, 5, 6, 7, 8, 9, :gap, 300 ])
    end

    it "lists every page when there are only a few" do
      expect(window(3, 5)).to eq([ 1, 2, 3, 4, 5 ])
    end
  end
end
