require "rails_helper"

RSpec.describe "Issuing goods", type: :system do
  let(:user) { create(:user) }
  let(:lisbon) { create(:warehouse, code: "LIS", name: "Lisbon") }
  let(:gloves) { create(:item, sku: "GLV-1", name: "Gloves", unit_of_measure: "box") }

  before do
    create(:stock_movement, warehouse: lisbon, quantity: 3,
      lot: create(:lot, item: gloves, lot_number: "G-SOON", expiry_date: Date.current + 5))
    create(:stock_movement, warehouse: lisbon, quantity: 10,
      lot: create(:lot, item: gloves, lot_number: "G-LATER", expiry_date: Date.current + 50))
    create(:stock_movement, warehouse: lisbon, quantity: 99,
      lot: create(:lot, item: gloves, lot_number: "G-OLD", expiry_date: Date.yesterday))

    sign_in_as(user)
    click_link "Issue goods"
  end

  def issue(quantity)
    select "GLV-1 · Gloves", from: "Item"
    select "Lisbon", from: "Warehouse"
    fill_in "Quantity", with: quantity
    fill_in "Reason (optional)", with: "ward 3"
    click_button "Issue"
  end

  it "takes from the lots that expire first and skips expired ones" do
    issue("5")

    expect(page).to have_css("[role=status]", text: "Issued 5 box of GLV-1: 3 from lot G-SOON and 2 from lot G-LATER")
    expect(page).to have_no_css("tr", text: "G-SOON")
    expect(page).to have_css("tr", text: /G-LATER.*8 box/)
    expect(page).to have_css("tr", text: /G-OLD.*Expired.*99 box/)
  end

  it "refuses to issue more than the usable stock" do
    issue("20")

    expect(page).to have_css("[role=alert]", text: "Requested 20 but only 13 available")
    expect(page).to have_field("Quantity", with: "20")
  end
end
