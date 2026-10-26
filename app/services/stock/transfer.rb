module Stock
  class Transfer < Operation
    def initialize(lot:, from:, to:, quantity:, user:)
      @lot = lot
      @from = from
      @to = to
      @quantity = quantity
      @user = user
    end

    def call
      quantity = positive_quantity(@quantity)
      raise SameWarehouse if @from == @to

      StockMovement.transaction do
        reserve(@lot, @from, quantity)
        transfer_id = SecureRandom.uuid

        [
          StockMovement.create!(
            lot: @lot, warehouse: @from, user: @user, kind: :transfer_out, quantity: -quantity, transfer_id: transfer_id
          ),
          StockMovement.create!(
            lot: @lot, warehouse: @to, user: @user, kind: :transfer_in, quantity: quantity, transfer_id: transfer_id
          )
        ]
      end
    end
  end
end
