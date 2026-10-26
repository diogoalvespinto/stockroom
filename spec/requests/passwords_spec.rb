require "rails_helper"

RSpec.describe "passwords", type: :request do
  let(:user) { create(:user) }

  describe "GET /passwords/new" do
    it "renders the reset request form" do
      get new_password_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /passwords" do
    it "emails reset instructions to a known address" do
      expect { post passwords_path, params: { email_address: user.email_address } }
        .to have_enqueued_mail(PasswordsMailer, :reset).with(user)

      expect(response).to redirect_to(new_session_path)
    end

    it "responds the same way for an unknown address without sending anything" do
      expect { post passwords_path, params: { email_address: "nobody@example.com" } }
        .not_to have_enqueued_mail

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq("Password reset instructions sent (if user with that email address exists).")
    end
  end

  describe "GET /passwords/:token/edit" do
    it "renders the new password form for a valid token" do
      get edit_password_path(user.password_reset_token)

      expect(response).to have_http_status(:ok)
    end

    it "rejects an invalid token" do
      get edit_password_path("invalid")

      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to eq("Password reset link is invalid or has expired.")
    end
  end

  describe "PUT /passwords/:token" do
    let(:token) { user.password_reset_token }

    context "when the passwords match" do
      before { create(:session, user: user) }

      it "changes the password and signs out every session" do
        put password_path(token), params: { password: "new-password", password_confirmation: "new-password" }

        expect(response).to redirect_to(new_session_path)
        expect(user.reload.authenticate("new-password")).to eq(user)
        expect(user.sessions).to be_empty
      end
    end

    context "when the passwords do not match" do
      it "keeps the old password" do
        put password_path(token), params: { password: "new-password", password_confirmation: "other" }

        expect(response).to redirect_to(edit_password_path(token))
        expect(user.reload.authenticate("password")).to eq(user)
      end
    end
  end
end
