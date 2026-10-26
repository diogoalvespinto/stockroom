require "rails_helper"

RSpec.describe "Receiving goods", type: :system do
  let(:user) { create(:user) }
  let!(:gloves) { create(:item, sku: "GLV-1", name: "Gloves", unit_of_measure: "box") }

  before do
    create(:warehouse, code: "LIS", name: "Lisbon")
    sign_in_as(user)
    click_link "Receive goods"
  end

  def fill_in_receipt(expiry_date:)
    select "GLV-1 · Gloves", from: "Item"
    select "Lisbon", from: "Warehouse"
    fill_in "Lot number", with: "G-100"
    fill_in "Expiry date", with: expiry_date
    fill_in "Quantity", with: "40"
    click_button "Receive"
  end

  it "adds the received lot to the stock on hand" do
    fill_in_receipt(expiry_date: "2027-03-31")

    expect(page).to have_css("[role=status]", text: "Received 40 box of GLV-1 into LIS (lot G-100)")
    expect(page).to have_css("tr", text: /LIS.*G-100.*2027-03-31.*40 box/)
  end

  it "explains a refused receipt and keeps what was typed" do
    create(:lot, item: gloves, lot_number: "G-100", expiry_date: Date.new(2027, 1, 31))

    fill_in_receipt(expiry_date: "2027-03-31")

    expect(page).to have_css("[role=alert]", text: "Lot G-100 already exists with expiry date 2027-01-31")
    expect(page).to have_select("Item", selected: "GLV-1 · Gloves")
    expect(page).to have_field("Lot number", with: "G-100")
  end
end
