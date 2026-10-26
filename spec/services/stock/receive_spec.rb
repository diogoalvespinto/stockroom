require "rails_helper"

RSpec.describe Stock::Receive do
  let(:item) { create(:item) }
  let(:warehouse) { create(:warehouse) }
  let(:user) { create(:user) }
  let(:expiry_date) { Date.new(2027, 6, 30) }

  def receive_stock(quantity: 10, lot_number: "L-100", expiry_date: self.expiry_date)
    described_class.call(
      item: item, warehouse: warehouse, lot_number: lot_number,
      expiry_date: expiry_date, quantity: quantity, user: user
    )
  end

  context "with a new lot number" do
    it "creates the lot and records a receipt" do
      movement = receive_stock

      expect(movement).to have_attributes(kind: "receipt", quantity: 10, warehouse: warehouse, user: user)
      expect(movement.lot).to have_attributes(item: item, lot_number: "L-100", expiry_date: expiry_date)
    end

    it "creates a lot without an expiry date" do
      expect(receive_stock(expiry_date: nil).lot.expiry_date).to be_nil
    end

    it "accepts the expiry date as an ISO 8601 string" do
      expect(receive_stock(expiry_date: "2027-06-30").lot.expiry_date).to eq(expiry_date)
    end
  end

  context "with an existing lot" do
    let!(:lot) { create(:lot, item: item, lot_number: "L-100", expiry_date: expiry_date) }

    it "adds to that lot, matching the lot number however it is typed" do
      expect { receive_stock(lot_number: " l-100 ") }.not_to change(Lot, :count)

      expect(StockMovement.balance(warehouse: warehouse, lot: lot)).to eq(10)
    end

    it "rejects a different expiry date" do
      expect { receive_stock(expiry_date: expiry_date + 1) }
        .to raise_error(Stock::ExpiryMismatch, "Lot L-100 already exists with expiry date 2027-06-30")

      expect(StockMovement.count).to eq(0)
    end
  end

  it "accepts a quantity typed into a form" do
    expect(receive_stock(quantity: "12").quantity).to eq(12)
  end

  [ 0, -5, 2.5, "ten", nil ].each do |quantity|
    it "rejects a quantity of #{quantity.inspect} without creating the lot" do
      expect { receive_stock(quantity: quantity) }
        .to raise_error(Stock::InvalidRequest, "Quantity must be a positive whole number")

      expect(Lot.count).to eq(0)
    end
  end

  it "rejects an expiry date that is not a date" do
    expect { receive_stock(expiry_date: "next spring") }
      .to raise_error(Stock::InvalidRequest, "Expiry date is not a valid date")
  end

  it "retries when a concurrent receipt creates the same lot first" do
    attempts = 0
    allow(Lot).to receive(:transaction).and_wrap_original do |original, *args, **options, &block|
      attempts += 1
      raise ActiveRecord::RecordNotUnique, "duplicate key" if attempts == 1

      original.call(*args, **options, &block)
    end

    expect { receive_stock }.to change(Lot, :count).by(1)
  end
end
