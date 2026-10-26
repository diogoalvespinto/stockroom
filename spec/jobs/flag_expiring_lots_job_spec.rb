require "rails_helper"

RSpec.describe FlagExpiringLotsJob do
  let(:today) { Date.new(2026, 10, 26) }
  let(:warehouse) { create(:warehouse) }
  let!(:user) { create(:user) }

  def lot(expiry_date:, stock: 5)
    create(:lot, expiry_date: expiry_date).tap do |lot|
      create(:stock_movement, lot: lot, warehouse: warehouse, quantity: stock) if stock
    end
  end

  def run
    described_class.perform_now(on: today)
  end

  it "flags lots in stock that expire within 30 days and emails every user about them" do
    other_user = create(:user)
    soon = lot(expiry_date: today + 10)
    lot(expiry_date: today + 31)
    lot(expiry_date: today - 1)
    lot(expiry_date: today + 5, stock: nil)

    freeze_time do
      expect { run }
        .to have_enqueued_mail(ExpiryMailer, :expiring_soon).with(params: { user: user, lots: [ soon ] }, args: [])
        .and have_enqueued_mail(ExpiryMailer, :expiring_soon).with(params: { user: other_user, lots: [ soon ] }, args: [])

      expect(soon.reload.expiry_alerted_at).to eq(Time.current)
    end
  end

  it "flags each lot only once" do
    lot(expiry_date: today + 10)
    run

    expect { run }.not_to have_enqueued_mail
  end

  it "only mentions lots that were not flagged before" do
    lot(expiry_date: today + 10).update!(expiry_alerted_at: 1.day.ago)
    fresh = lot(expiry_date: today + 20)

    expect { run }.to have_enqueued_mail(ExpiryMailer, :expiring_soon).with(params: { user: user, lots: [ fresh ] }, args: [])
  end

  it "lists a lot once even when it is stocked in several warehouses" do
    soon = lot(expiry_date: today + 10)
    create(:stock_movement, lot: soon, warehouse: create(:warehouse), quantity: 3)

    expect { run }.to have_enqueued_mail(ExpiryMailer, :expiring_soon).with(params: { user: user, lots: [ soon ] }, args: [])
  end

  it "does nothing when no lot is about to expire" do
    lot(expiry_date: today + 90)

    expect { run }.not_to have_enqueued_mail
  end
end
