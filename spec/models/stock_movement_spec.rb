require "rails_helper"

RSpec.describe StockMovement, type: :model do
  subject(:movement) { build(:stock_movement) }

  describe "associations" do
    it { is_expected.to belong_to(:lot) }
    it { is_expected.to belong_to(:warehouse) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it do
      is_expected.to define_enum_for(:kind)
        .with_values(
          receipt: "receipt",
          issue: "issue",
          transfer_out: "transfer_out",
          transfer_in: "transfer_in",
          adjustment: "adjustment"
        )
        .backed_by_column_of_type(:enum)
        .validating
    end

    it { is_expected.to validate_numericality_of(:quantity).only_integer.is_other_than(0) }
    it { is_expected.not_to validate_presence_of(:reason) }

    %i[receipt transfer_in].each do |kind|
      context "when the movement is a #{kind}" do
        subject(:movement) { build(:stock_movement, kind: kind) }

        it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
      end
    end

    %i[issue transfer_out].each do |kind|
      context "when the movement is an #{kind}" do
        subject(:movement) { build(:stock_movement, kind) }

        it { is_expected.to validate_numericality_of(:quantity).is_less_than(0) }
      end
    end

    context "when the movement is an adjustment" do
      subject(:movement) { build(:stock_movement, :adjustment) }

      it { is_expected.to validate_presence_of(:reason) }
      it { is_expected.to allow_values(-5, 5).for(:quantity) }
    end

    %i[transfer_out transfer_in].each do |kind|
      context "when the movement is a #{kind}" do
        subject(:movement) { build(:stock_movement, kind) }

        it { is_expected.to validate_presence_of(:transfer_id) }
      end
    end

    %i[receipt issue adjustment].each do |kind|
      context "when the movement is a #{kind}" do
        subject(:movement) { build(:stock_movement, kind: kind) }

        it { is_expected.to validate_absence_of(:transfer_id) }
      end
    end
  end

  describe "balances" do
    let(:warehouse) { create(:warehouse) }
    let(:lot) { create(:lot) }
    let(:other_lot) { create(:lot) }

    before do
      create(:stock_movement, lot: lot, warehouse: warehouse, quantity: 10)
      create(:stock_movement, :issue, lot: lot, warehouse: warehouse, quantity: -3)
      create(:stock_movement, lot: other_lot, warehouse: warehouse, quantity: 4)
      create(:stock_movement, lot: lot, quantity: 50)
    end

    describe ".balance" do
      it "sums the signed quantities of one lot in one warehouse" do
        expect(described_class.balance(warehouse: warehouse, lot: lot)).to eq(7)
      end

      it "is zero for a lot that never entered the warehouse" do
        expect(described_class.balance(warehouse: warehouse, lot: create(:lot))).to eq(0)
      end
    end

    describe ".balances" do
      it "returns the balance of each lot that has movements in the warehouse" do
        balances = described_class.balances(warehouse: warehouse, lots: [ lot, other_lot, create(:lot) ])

        expect(balances).to eq(lot.id => 7, other_lot.id => 4)
      end
    end
  end

  describe "append-only ledger" do
    subject(:movement) { create(:stock_movement) }

    it "cannot be updated through the model" do
      expect { movement.update(quantity: 5) }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "cannot be destroyed through the model" do
      expect { movement.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "rejects an update that bypasses the model" do
      expect { described_class.where(id: movement.id).update_all(quantity: 5) }
        .to raise_error(ActiveRecord::StatementInvalid, /append-only: UPDATE is not allowed/)
    end

    it "rejects a delete that bypasses the model" do
      expect { described_class.where(id: movement.id).delete_all }
        .to raise_error(ActiveRecord::StatementInvalid, /append-only: DELETE is not allowed/)
    end
  end

  describe "database constraints" do
    it "rejects an outbound movement with a positive quantity" do
      movement = build(:stock_movement, :issue, quantity: 5)

      expect { movement.save!(validate: false) }
        .to raise_error(ActiveRecord::CheckViolation, /stock_movements_quantity_sign_matches_kind/)
    end

    it "rejects an adjustment with a blank reason" do
      movement = build(:stock_movement, :adjustment, reason: " ")

      expect { movement.save!(validate: false) }
        .to raise_error(ActiveRecord::CheckViolation, /stock_movements_adjustment_has_reason/)
    end

    it "rejects a transfer leg without a transfer id" do
      movement = build(:stock_movement, :transfer_out, transfer_id: nil)

      expect { movement.save!(validate: false) }
        .to raise_error(ActiveRecord::CheckViolation, /stock_movements_transfer_id_matches_kind/)
    end
  end
end
