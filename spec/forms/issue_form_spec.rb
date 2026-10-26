require "rails_helper"

RSpec.describe IssueForm do
  let(:user) { create(:user) }
  let(:item) { create(:item, sku: "GLV-1", unit_of_measure: "box") }
  let(:warehouse) { create(:warehouse) }

  before do
    create(:stock_movement, warehouse: warehouse, quantity: 3,
      lot: create(:lot, item: item, lot_number: "G-1", expiry_date: Date.current + 5))
    create(:stock_movement, warehouse: warehouse, quantity: 10,
      lot: create(:lot, item: item, lot_number: "G-2", expiry_date: Date.current + 50))
  end

  def form(**overrides)
    described_class.new({ item_id: item.id, warehouse_id: warehouse.id, quantity: "5", reason: "" }.merge(overrides))
  end

  it "summarises how the request was split across lots" do
    issue = form

    expect(issue.save(user: user)).to be(true)
    expect(issue.summary).to eq("Issued 5 box of GLV-1: 3 from lot G-1 and 2 from lot G-2")
  end

  it "stores a blank reason as no reason" do
    issue = form
    issue.save(user: user)

    expect(issue.movements.map(&:reason)).to all(be_nil)
  end

  it "reports a shortage as an error" do
    issue = form(quantity: "20")

    expect(issue.save(user: user)).to be(false)
    expect(issue.errors.full_messages).to eq([ "Requested 20 but only 13 available" ])
  end

  it "requires an item, a warehouse and a quantity" do
    expect(described_class.new.tap(&:validate).errors.attribute_names).to contain_exactly(:item_id, :warehouse_id, :quantity)
  end
end
