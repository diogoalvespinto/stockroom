require "rails_helper"

RSpec.describe Warehouse, type: :model do
  subject(:warehouse) { build(:warehouse) }

  describe "associations" do
    it { is_expected.to have_many(:stock_movements).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).case_insensitive }
    it { is_expected.to validate_length_of(:code).is_at_most(10) }
  end

  describe "normalization" do
    it { is_expected.to normalize(:code).from(" lis-01 ").to("LIS-01") }
  end
end
