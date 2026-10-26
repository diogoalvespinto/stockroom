require "rails_helper"

RSpec.describe PurgeIdempotencyKeysJob do
  it "deletes keys older than 24 hours and keeps recent ones" do
    old_key = travel_to(25.hours.ago) { create(:idempotency_key) }
    recent_key = travel_to(23.hours.ago) { create(:idempotency_key) }

    described_class.perform_now

    expect(IdempotencyKey.all).to contain_exactly(recent_key)
    expect { old_key.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
