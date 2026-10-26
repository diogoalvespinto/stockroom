require "rails_helper"

RSpec.describe "Expiring lots report", type: :system do
  let(:user) { create(:user) }
  let(:warehouse) { create(:warehouse, code: "LIS") }

  before do
    { "SOON" => 3, "NEXT-MONTH" => 25, "LATER" => 80 }.each do |lot_number, days|
      create(:stock_movement, warehouse: warehouse, quantity: 4,
        lot: create(:lot, lot_number: lot_number, expiry_date: Date.current + days))
    end
    sign_in_as(user)
    click_link "Expiring lots"
  end

  it "shows lots expiring in the next 30 days by default" do
    expect(page).to have_select("Expiring within", selected: "30 days")
    expect(page).to have_css("tr", text: /SOON.*LIS/)
    expect(page).to have_css("tr", text: "in 25 days")
    expect(page).to have_no_text("LATER")
  end

  it "narrows the window without leaving the page", :js do
    expect(page).to have_css("h1", text: "Expiring lots")
    expect(page).to have_no_button("Show")
    page.execute_script("document.querySelector('h1').dataset.untouched = 'yes'")

    select "7 days", from: "Expiring within"

    expect(page).to have_no_text("NEXT-MONTH")
    expect(page).to have_css("tr", text: "SOON")
    expect(page).to have_current_path(expiring_report_path(days: 7))
    expect(page).to have_css("h1[data-untouched=yes]")
  end

  it "falls back to 30 days for a window it does not offer" do
    visit expiring_report_path(days: 1000)

    expect(page).to have_select("Expiring within", selected: "30 days")
  end
end
