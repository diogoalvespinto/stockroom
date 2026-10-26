require "rails_helper"

RSpec.describe "db/seeds.rb" do
  before { allow($stdout).to receive(:puts) }

  def seed
    Rails.application.load_seed
  end

  it "builds a demo inventory through the stock services" do
    seed

    expect(User.find_by!(email_address: "demo@example.com").authenticate("password")).to be_truthy
    expect(StockMovement.group(:kind).count).to eq(
      "receipt" => 9, "issue" => 2, "transfer_out" => 1, "transfer_in" => 1, "adjustment" => 1
    )
  end

  it "covers every report with something to show" do
    seed

    expect(ExpiringLotsReport.new.rows.map { |row| row.lot.lot_number }).to include("SAL-2504", "MSK-2503")
    expect(BelowReorderLevelReport.new.rows.map { |row| row.item.sku }).to include("MSK-200", "THR-001")
    expect(StockOnHandReport.new.rows.map(&:lot)).to include(an_object_having_attributes(lot_number: "MSK-2410"))
  end

  it "can run again without duplicating anything" do
    seed

    expect { seed }.not_to change { [ User.count, Warehouse.count, Item.count, Lot.count, StockMovement.count ] }
  end
end
