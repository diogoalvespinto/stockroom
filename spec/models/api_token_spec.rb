require "rails_helper"

RSpec.describe ApiToken, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "creation" do
    it "exposes the plain token once and stores only its digest" do
      api_token = create(:api_token)

      expect(api_token.token).to be_present
      expect(api_token.token_digest).to eq(OpenSSL::Digest::SHA256.hexdigest(api_token.token))
      expect(described_class.find(api_token.id).token).to be_nil
    end
  end

  describe ".authenticate" do
    let!(:api_token) { create(:api_token) }

    it "finds the token from its plain value and records when it was used" do
      freeze_time do
        expect(described_class.authenticate(api_token.token)).to eq(api_token)
        expect(api_token.reload.last_used_at).to eq(Time.current)
      end
    end

    it "rejects an unknown token" do
      expect(described_class.authenticate("not-a-token")).to be_nil
    end

    it "rejects a blank token" do
      expect(described_class.authenticate("")).to be_nil
    end
  end
end
