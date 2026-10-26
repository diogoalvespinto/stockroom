require "rails_helper"

RSpec.describe "Signing in", type: :system do
  let!(:user) { create(:user, email_address: "ana@example.com", password: "s3cret-pass") }

  it "signs a user in and out" do
    visit new_session_path
    fill_in "Email address", with: "ana@example.com"
    fill_in "Password", with: "s3cret-pass"
    click_on "Sign in"

    expect(page).to have_text("ana@example.com")

    click_on "Sign out"

    expect(page).to have_current_path(new_session_path)
    expect(page).to have_no_button("Sign out")
  end

  it "shows an alert for a wrong password" do
    visit new_session_path
    fill_in "Email address", with: "ana@example.com"
    fill_in "Password", with: "wrong"
    click_on "Sign in"

    expect(page).to have_css("[role=alert]", text: "Try another email address or password.")
    expect(page).to have_no_button("Sign out")
  end
end
