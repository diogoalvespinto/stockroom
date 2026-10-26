require "rails_helper"

RSpec.describe "Below reorder level report", type: :system do
  let(:user) { create(:user) }

  it "lists the items that need reordering" do
    gloves = create(:item, sku: "GLV-1", name: "Gloves", unit_of_measure: "box", reorder_level: 50)
    create(:stock_movement, quantity: 20, lot: create(:lot, item: gloves))
    create(:item, sku: "MSK-1", reorder_level: 0)

    sign_in_as(user)
    click_link "Reorder"

    expect(page).to have_css("tr", text: /GLV-1 · Gloves.*20 box.*50.*30/)
    expect(page).to have_no_text("MSK-1")
  end

  it "says so when nothing needs reordering" do
    sign_in_as(user)
    click_link "Reorder"

    expect(page).to have_text("Every item is at or above its reorder level.")
  end
end
