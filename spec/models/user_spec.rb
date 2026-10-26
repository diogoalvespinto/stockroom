require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:stock_movements).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to have_secure_password }
    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
    it { is_expected.to allow_value("ana@example.com").for(:email_address) }
    it { is_expected.not_to allow_value("ana@", "ana.example.com").for(:email_address) }
  end

  describe "normalization" do
    it { is_expected.to normalize(:email_address).from("  Ana@Example.COM ").to("ana@example.com") }
  end
end
