require "rails_helper"

RSpec.describe "sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /session/new" do
    it "renders the sign-in form" do
      get new_session_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    context "with valid credentials" do
      it "starts a session and sets the session cookie" do
        expect { sign_in_as(user) }.to change(user.sessions, :count).by(1)

        expect(response).to redirect_to(root_url)
        expect(cookies[:session_id]).to be_present
      end

      it "returns to the page that required authentication" do
        delete session_path
        sign_in_as(user)

        expect(response).to redirect_to(session_url)
      end
    end

    context "with invalid credentials" do
      it "does not start a session" do
        expect { sign_in_as(user, password: "wrong") }.not_to change(Session, :count)

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end
    end
  end

  describe "DELETE /session" do
    context "when signed in" do
      before { sign_in_as(user) }

      it "ends the session and clears the cookie" do
        expect { delete session_path }.to change(Session, :count).by(-1)

        expect(response).to redirect_to(new_session_path)
        expect(response).to have_http_status(:see_other)
        expect(cookies[:session_id]).to be_blank
      end
    end

    context "when not signed in" do
      it "redirects to the sign-in form" do
        delete session_path

        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
