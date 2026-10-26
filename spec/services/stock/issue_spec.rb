require "rails_helper"

RSpec.describe Stock::Issue do
  let(:item) { create(:item) }
  let(:warehouse) { create(:warehouse) }
  let(:user) { create(:user) }
  let(:today) { Date.new(2026, 10, 26) }

  def lot(expiry_date:, stock:, item: self.item, warehouse: self.warehouse)
    create(:lot, item: item, expiry_date: expiry_date).tap do |lot|
      create(:stock_movement, lot: lot, warehouse: warehouse, quantity: stock)
    end
  end

  def issue(quantity, reason: nil)
    described_class.call(item: item, warehouse: warehouse, quantity: quantity, user: user, reason: reason, on: today)
  end

  def lines(movements)
    movements.map { |movement| [ movement.lot, movement.quantity ] }
  end

  describe "first-expiry-first-out allocation" do
    it "takes from the lot that expires first" do
      lot(expiry_date: today + 60, stock: 10)
      sooner = lot(expiry_date: today + 10, stock: 10)

      expect(lines(issue(4))).to eq([ [ sooner, -4 ] ])
    end

    it "splits the request across lots when the first one runs out" do
      sooner = lot(expiry_date: today + 10, stock: 3)
      later = lot(expiry_date: today + 60, stock: 10)

      expect(lines(issue(5))).to eq([ [ sooner, -3 ], [ later, -2 ] ])
    end

    it "uses lots without an expiry date last" do
      undated = lot(expiry_date: nil, stock: 10)
      dated = lot(expiry_date: today + 400, stock: 1)

      expect(lines(issue(3))).to eq([ [ dated, -1 ], [ undated, -2 ] ])
    end
  end

  describe "expiry" do
    it "never issues from an expired lot but still issues a lot on its expiry date" do
      lot(expiry_date: today - 1, stock: 10)
      expiring_today = lot(expiry_date: today, stock: 2)

      expect(lines(issue(2))).to eq([ [ expiring_today, -2 ] ])
    end

    it "does not count expired stock as available" do
      lot(expiry_date: today - 1, stock: 10)
      lot(expiry_date: today, stock: 2)

      expect { issue(3) }.to raise_error(Stock::InsufficientStock, "Requested 3 but only 2 available")
    end
  end

  describe "stock boundaries" do
    it "only counts stock in the requested warehouse" do
      lot(expiry_date: today + 10, stock: 2)
      lot(expiry_date: today + 10, stock: 50, warehouse: create(:warehouse))

      expect { issue(3) }.to raise_error(Stock::InsufficientStock, "Requested 3 but only 2 available")
    end

    it "ignores lots of other items" do
      lot(expiry_date: today + 10, stock: 50, item: create(:item))

      expect { issue(1) }.to raise_error(Stock::InsufficientStock, "Requested 1 but only 0 available")
    end

    it "can empty the warehouse exactly" do
      sooner = lot(expiry_date: today + 10, stock: 3)
      later = lot(expiry_date: today + 20, stock: 4)
      issue(7)

      expect(StockMovement.balances(warehouse: warehouse, lots: [ sooner, later ])).to eq(sooner.id => 0, later.id => 0)
    end

    it "writes nothing when the request cannot be filled" do
      lot(expiry_date: today + 10, stock: 3)
      lot(expiry_date: today + 20, stock: 4)

      expect { expect { issue(8) }.to raise_error(Stock::InsufficientStock) }.not_to change(StockMovement, :count)
    end
  end

  it "records who issued the stock and why" do
    lot(expiry_date: today + 10, stock: 5)

    expect(issue(1, reason: "order 1042").first).to have_attributes(kind: "issue", user: user, reason: "order 1042")
  end

  it "rejects a quantity that is not a positive whole number" do
    expect { issue(0) }.to raise_error(Stock::InvalidRequest, "Quantity must be a positive whole number")
  end
end
