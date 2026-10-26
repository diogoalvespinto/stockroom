require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  describe "#reset" do
    let(:user) { create(:user) }
    let(:mail) { described_class.reset(user) }

    it "is addressed to the user" do
      expect(mail.to).to eq([ user.email_address ])
      expect(mail.subject).to eq("Reset your password")
    end

    it "links to a reset page that identifies the user" do
      token = mail.text_part.body.decoded[%r{/passwords/([^/]+)/edit}, 1]

      expect(User.find_by_password_reset_token!(token)).to eq(user)
    end
  end
end
