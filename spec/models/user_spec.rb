require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to have_secure_password }
  end

  describe "normalization" do
    it { is_expected.to normalize(:email_address).from("  Ana@Example.COM ").to("ana@example.com") }
  end
end
