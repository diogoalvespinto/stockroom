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
end
