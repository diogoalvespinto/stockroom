module Stock
  class Receive < Operation
    def initialize(item:, warehouse:, lot_number:, quantity:, user:, expiry_date: nil)
      @item = item
      @warehouse = warehouse
      @lot_number = lot_number
      @quantity = quantity
      @user = user
      @expiry_date = expiry_date
    end

    def call
      quantity = positive_quantity(@quantity)
      expiry_date = parse_expiry_date

      StockMovement.transaction do
        lot = find_or_create_lot(expiry_date)
        raise ExpiryMismatch, lot unless lot.expiry_date == expiry_date

        StockMovement.create!(lot: lot, warehouse: @warehouse, user: @user, kind: :receipt, quantity: quantity)
      end
    end

    private
      def parse_expiry_date
        date = ActiveModel::Type::Date.new.cast(@expiry_date)
        raise InvalidRequest, "Expiry date is not a valid date" if @expiry_date.present? && date.nil?

        date
      end

      def find_or_create_lot(expiry_date)
        Lot.transaction(requires_new: true) do
          @item.lots.find_or_create_by!(lot_number: @lot_number) { |lot| lot.expiry_date = expiry_date }
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
  end
end
