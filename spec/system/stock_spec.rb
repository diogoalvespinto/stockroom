require "rails_helper"

RSpec.describe "Stock on hand", type: :system do
  let(:user) { create(:user) }
  let(:lisbon) { create(:warehouse, code: "LIS", name: "Lisbon") }
  let(:porto) { create(:warehouse, code: "OPO", name: "Porto") }
  let(:gloves) { create(:item, sku: "GLV-1", name: "Gloves", unit_of_measure: "box") }

  before do
    create(:stock_movement, warehouse: lisbon, quantity: 12,
      lot: create(:lot, item: gloves, lot_number: "G-1", expiry_date: Date.current + 30))
    create(:stock_movement, warehouse: porto, quantity: 5,
      lot: create(:lot, item: gloves, lot_number: "G-2", expiry_date: Date.yesterday))
  end

  it "asks visitors to sign in first" do
    visit root_path

    expect(page).to have_current_path(new_session_path)
  end

  it "lists the lots in stock in each warehouse" do
    sign_in_as(user)

    expect(page).to have_css("h1", text: "Stock on hand")
    expect(page).to have_css("tr", text: /LIS.*GLV-1 · Gloves.*G-1.*12 box/)
    expect(page).to have_css("tr", text: /OPO.*G-2.*Expired.*5 box/)
  end

  it "filters by warehouse without javascript" do
    sign_in_as(user)
    select "Porto", from: "Warehouse"
    click_on "Filter"

    expect(page).to have_no_text("G-1")
    expect(page).to have_text("G-2")
  end

  it "filters by warehouse in place as soon as one is chosen", :js do
    sign_in_as(user)
    expect(page).to have_no_button("Filter")
    page.execute_script("document.querySelector('h1').dataset.untouched = 'yes'")

    select "Porto", from: "Warehouse"

    expect(page).to have_no_text("G-1")
    expect(page).to have_text("G-2")
    expect(page).to have_current_path(root_path(warehouse_id: porto.id))
    expect(page).to have_css("h1[data-untouched=yes]")
  end

  context "with more lots than fit on a page" do
    before { stub_const("StockOnHandReport::PER_PAGE", 1) }

    it "pages forwards and back" do
      sign_in_as(user)

      expect(page).to have_text("G-1")
      expect(page).to have_no_text("G-2")
      expect(page).to have_no_link("Previous")

      click_on "Next"

      expect(page).to have_text("G-2")
      expect(page).to have_no_text("G-1")
      expect(page).to have_no_link("Next")

      click_on "Previous"

      expect(page).to have_text("G-1")
    end

    it "keeps the warehouse filter from page to page" do
      create(:stock_movement, warehouse: porto, quantity: 3,
        lot: create(:lot, item: gloves, lot_number: "G-3", expiry_date: Date.current + 60))
      sign_in_as(user)
      select "Porto", from: "Warehouse"
      click_on "Filter"
      click_on "Next"

      expect(page).to have_text("G-3")
      expect(page).to have_no_text("G-1")
    end

    it "shows the first page for a page number it does not understand" do
      sign_in_as(user)
      visit root_path(page: "last")

      expect(page).to have_text("G-1")
    end

    it "pages in place and keeps the page in the address", :js do
      sign_in_as(user)
      page.execute_script("document.querySelector('h1').dataset.untouched = 'yes'")

      click_on "Next"

      expect(page).to have_text("G-2")
      expect(page).to have_current_path(root_path(page: 2))
      expect(page).to have_css("h1[data-untouched=yes]")
    end
  end
end
