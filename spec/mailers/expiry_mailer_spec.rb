require "rails_helper"

RSpec.describe ExpiryMailer, type: :mailer do
  describe "#expiring_soon" do
    let(:user) { create(:user) }
    let(:item) { create(:item, sku: "GLV-1", name: "Gloves") }
    let(:later) { create(:lot, item: item, lot_number: "G-2", expiry_date: Date.new(2026, 11, 20)) }
    let(:sooner) { create(:lot, item: item, lot_number: "G-1", expiry_date: Date.new(2026, 11, 2)) }

    it "lists the lots, soonest first, and links to the report" do
      mail = described_class.with(user: user, lots: [ later, sooner ]).expiring_soon

      expect(mail.to).to eq([ user.email_address ])
      expect(mail.subject).to eq("2 lots expire within 30 days")
      expect(mail.text_part.body.decoded).to match(/2026-11-02.*G-1.*\n.*2026-11-20.*G-2/)
      expect(mail.html_part.body.decoded).to include("http://example.com/reports/expiring")
    end

    it "uses the singular for one lot" do
      mail = described_class.with(user: user, lots: [ sooner ]).expiring_soon

      expect(mail.subject).to eq("1 lot expires within 30 days")
    end
  end
end
