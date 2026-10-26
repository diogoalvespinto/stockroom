module SystemHelpers
  def sign_in_as(user, password: "password")
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_on "Sign in"

    expect(page).to have_button("Sign out")
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
