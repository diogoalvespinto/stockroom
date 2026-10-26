require "rails_helper"

RSpec.describe "Home page", type: :system do
  it "shows the application name" do
    visit root_path

    expect(page).to have_css("h1", text: "Stockroom")
  end

  it "boots Turbo in a real browser", :js do
    visit root_path

    expect(page).to have_css("h1", text: "Stockroom")
    expect(page.evaluate_script("typeof window.Turbo")).to eq("object")
  end
end
