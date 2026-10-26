require "rails_helper"

RSpec.describe Stock::Adjust do
  let(:lot) { create(:lot) }
  let(:warehouse) { create(:warehouse) }
  let(:user) { create(:user) }

  before { create(:stock_movement, lot: lot, warehouse: warehouse, quantity: 3) }

  def adjust(quantity, reason: "cycle count")
    described_class.call(lot: lot, warehouse: warehouse, quantity: quantity, reason: reason, user: user)
  end

  def balance
    StockMovement.balance(warehouse: warehouse, lot: lot)
  end

  it "adds stock that was found" do
    movement = adjust(2, reason: "found behind shelf")

    expect(movement).to have_attributes(kind: "adjustment", quantity: 2, reason: "found behind shelf", user: user)
    expect(balance).to eq(5)
  end

  it "removes stock that was lost" do
    expect { adjust(-3) }.to change { balance }.from(3).to(0)
  end

  it "refuses to remove more than the warehouse holds" do
    expect { expect { adjust(-4) }.to raise_error(Stock::InsufficientStock, "Requested 4 but only 3 available") }
      .not_to change(StockMovement, :count)
  end

  it "requires a reason" do
    expect { expect { adjust(1, reason: " ") }.to raise_error(ActiveRecord::RecordInvalid, /Reason can't be blank/) }
      .not_to change(StockMovement, :count)
  end

  [ 0, "1.5", "lots", nil ].each do |quantity|
    it "rejects a quantity of #{quantity.inspect}" do
      expect { adjust(quantity) }.to raise_error(Stock::InvalidRequest, "Quantity must be a non-zero whole number")
    end
  end
end
