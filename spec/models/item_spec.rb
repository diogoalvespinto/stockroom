require "rails_helper"

RSpec.describe Item, type: :model do
  subject(:item) { build(:item) }

  describe "associations" do
    it { is_expected.to have_many(:lots).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:sku) }
    it { is_expected.to validate_uniqueness_of(:sku).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:unit_of_measure) }
    it { is_expected.to validate_numericality_of(:reorder_level).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "normalization" do
    it { is_expected.to normalize(:sku).from(" ab-123 ").to("AB-123") }
  end

  describe "database constraints" do
    it "rejects a negative reorder level that skips validations" do
      item = create(:item)

      expect { item.update_column(:reorder_level, -1) }
        .to raise_error(ActiveRecord::CheckViolation, /items_reorder_level_not_negative/)
    end
  end
end
