require "rails_helper"

RSpec.describe Lot, type: :model do
  subject(:lot) { build(:lot) }

  describe "associations" do
    it { is_expected.to belong_to(:item) }
    it { is_expected.to have_many(:stock_movements).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:lot_number) }
    it { is_expected.to validate_uniqueness_of(:lot_number).scoped_to(:item_id).case_insensitive }
    it { is_expected.to allow_value(nil).for(:expiry_date) }
  end

  describe "normalization" do
    it { is_expected.to normalize(:lot_number).from(" l2026-a ").to("L2026-A") }
  end

  describe ".usable_on" do
    it "keeps lots expiring on or after the date and lots without expiry" do
      today = Date.new(2026, 10, 26)
      create(:lot, expiry_date: today - 1)
      expiring_today = create(:lot, expiry_date: today)
      later = create(:lot, expiry_date: today + 30)
      no_expiry = create(:lot, :without_expiry)

      expect(described_class.usable_on(today)).to contain_exactly(expiring_today, later, no_expiry)
    end
  end

  describe ".fefo" do
    it "orders by expiry date with undated lots last and ties broken by id" do
      later = create(:lot, expiry_date: Date.new(2027, 3, 1))
      no_expiry = create(:lot, :without_expiry)
      sooner = create(:lot, expiry_date: Date.new(2027, 1, 1))
      sooner_twin = create(:lot, expiry_date: Date.new(2027, 1, 1))

      expect(described_class.fefo).to eq([ sooner, sooner_twin, later, no_expiry ])
    end
  end

  describe "#expired?" do
    let(:today) { Date.new(2026, 10, 26) }

    it "is expired once the expiry date has passed" do
      lot = build(:lot, expiry_date: today - 1)

      expect(lot).to be_expired(on: today)
    end

    it "is still usable on its expiry date" do
      lot = build(:lot, expiry_date: today)

      expect(lot).not_to be_expired(on: today)
    end

    it "never expires without an expiry date" do
      lot = build(:lot, :without_expiry)

      expect(lot).not_to be_expired(on: today)
    end

    it "compares against the current date by default" do
      expect(build(:lot, :expired)).to be_expired
    end
  end
end
