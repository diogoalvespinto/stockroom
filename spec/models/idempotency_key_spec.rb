require "rails_helper"

RSpec.describe IdempotencyKey, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "database constraints" do
    it "allows each key once per user" do
      existing = create(:idempotency_key)

      expect { create(:idempotency_key, user: existing.user, key: existing.key) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
