require "spec_helper"
require_relative "../../../app/services/stock"
require_relative "../../../app/services/stock/allocation"

RSpec.describe Stock::Allocation do
  let(:first) { double("first lot", id: 1) }
  let(:second) { double("second lot", id: 2) }
  let(:third) { double("third lot", id: 3) }

  def allocate(quantity, balances)
    described_class.new(lots: [ first, second, third ], balances: balances, quantity: quantity)
      .lines.map { |line| [ line.lot, line.quantity ] }
  end

  it "takes everything from the first lot when it has enough" do
    expect(allocate(5, 1 => 10, 2 => 10)).to eq([ [ first, 5 ] ])
  end

  it "splits the quantity across lots in the order given" do
    expect(allocate(12, 1 => 5, 2 => 4, 3 => 10)).to eq([ [ first, 5 ], [ second, 4 ], [ third, 3 ] ])
  end

  it "empties a lot exactly when the quantity matches its balance" do
    expect(allocate(5, 1 => 5, 2 => 10)).to eq([ [ first, 5 ] ])
  end

  it "skips lots without stock" do
    expect(allocate(3, 1 => 0, 3 => 7)).to eq([ [ third, 3 ] ])
  end

  it "refuses to allocate more than the lots hold" do
    expect { allocate(20, 1 => 5, 3 => 10) }.to raise_error(Stock::InsufficientStock) do |error|
      expect(error).to have_attributes(requested: 20, available: 15)
    end
  end
end
