require "rails_helper"

RSpec.describe ExpiringLotsReport do
  let(:today) { Date.new(2026, 10, 26) }
  let(:warehouse) { create(:warehouse) }

  def lot_in_stock(lot_number, expiry_date, quantity: 5)
    create(:lot, lot_number: lot_number, expiry_date: expiry_date).tap do |lot|
      create(:stock_movement, lot: lot, warehouse: warehouse, quantity: quantity)
    end
  end

  it "lists lots in stock that expire within the window, soonest first" do
    lot_in_stock("LATER", today + 30)
    lot_in_stock("TODAY", today)
    lot_in_stock("OUTSIDE", today + 31)
    lot_in_stock("EXPIRED", today - 1)
    create(:lot, lot_number: "NO-STOCK", expiry_date: today + 3)

    rows = described_class.new(within_days: 30, on: today).rows

    expect(rows.map { |row| row.lot.lot_number }).to eq(%w[TODAY LATER])
  end

  it "counts the days left until each lot expires" do
    report = described_class.new(on: today)

    expect(report.days_left(build(:lot, expiry_date: today + 3))).to eq(3)
  end
end
