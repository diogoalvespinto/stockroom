require "rails_helper"

RSpec.describe Stock::Issue, "with concurrent requests" do
  include_context "with committed data"

  it "never lets two simultaneous issues overdraw a lot" do
    warehouse = create(:warehouse)
    lot = create(:lot)
    item = lot.item
    user = create(:user)
    create(:stock_movement, lot: lot, warehouse: warehouse, quantity: 10)

    both_read_balances = Concurrent::CyclicBarrier.new(2)
    allow(StockMovement).to receive(:balances).and_wrap_original do |original, **args|
      original.call(**args).tap { both_read_balances.wait(1) }
    end

    outcomes = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(item: item, warehouse: warehouse, quantity: 7, user: user)
          :issued
        rescue Stock::InsufficientStock
          :refused
        end
      end
    end.map(&:value)

    expect(outcomes).to contain_exactly(:issued, :refused)
    expect(StockMovement.balance(warehouse: warehouse, lot: lot)).to eq(3)
  end
end
