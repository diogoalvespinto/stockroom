require "rails_helper"

RSpec.describe Stock::Transfer do
  let(:lot) { create(:lot) }
  let(:source) { create(:warehouse) }
  let(:destination) { create(:warehouse) }
  let(:user) { create(:user) }

  before { create(:stock_movement, lot: lot, warehouse: source, quantity: 10) }

  def transfer(quantity, from: source, to: destination)
    described_class.call(lot: lot, from: from, to: to, quantity: quantity, user: user)
  end

  def balance(warehouse)
    StockMovement.balance(warehouse: warehouse, lot: lot)
  end

  it "moves stock out of the source and into the destination" do
    transfer(4)

    expect([ balance(source), balance(destination) ]).to eq([ 6, 4 ])
  end

  it "links both legs with the same transfer id" do
    outgoing, incoming = transfer(4)

    expect(outgoing).to have_attributes(kind: "transfer_out", quantity: -4, warehouse: source)
    expect(incoming).to have_attributes(kind: "transfer_in", quantity: 4, warehouse: destination)
    expect(outgoing.transfer_id).to be_present.and eq(incoming.transfer_id)
  end

  it "refuses to move more than the source holds" do
    create(:stock_movement, lot: lot, warehouse: destination, quantity: 50)

    expect { expect { transfer(11) }.to raise_error(Stock::InsufficientStock, "Requested 11 but only 10 available") }
      .not_to change(StockMovement, :count)
  end

  it "rolls back the outgoing leg when the incoming leg fails" do
    allow(StockMovement).to receive(:create!).and_call_original
    allow(StockMovement).to receive(:create!).with(hash_including(kind: :transfer_in))
      .and_raise(ActiveRecord::StatementInvalid, "connection lost")

    expect { expect { transfer(4) }.to raise_error(ActiveRecord::StatementInvalid) }
      .not_to change(StockMovement, :count)
  end

  it "refuses to transfer within the same warehouse" do
    expect { transfer(1, to: source) }
      .to raise_error(Stock::SameWarehouse, "Source and destination warehouses must be different")
  end

  it "can move an expired lot, for example into quarantine" do
    lot.update!(expiry_date: Date.yesterday)

    expect { transfer(10) }.to change { balance(destination) }.from(0).to(10)
  end

  it "rejects a quantity that is not a positive whole number" do
    expect { transfer(-1) }.to raise_error(Stock::InvalidRequest, "Quantity must be a positive whole number")
  end
end
