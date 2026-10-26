module Stock
  class Adjust < Operation
    def initialize(lot:, warehouse:, quantity:, reason:, user:)
      @lot = lot
      @warehouse = warehouse
      @quantity = quantity
      @reason = reason
      @user = user
    end

    def call
      quantity = whole_number(@quantity)
      raise InvalidRequest, "Quantity must be a non-zero whole number" if quantity.nil? || quantity.zero?

      StockMovement.transaction do
        reserve(@lot, @warehouse, -quantity) if quantity.negative?

        StockMovement.create!(
          lot: @lot, warehouse: @warehouse, user: @user, kind: :adjustment, quantity: quantity, reason: @reason
        )
      end
    end
  end
end
