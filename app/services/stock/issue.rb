module Stock
  class Issue < Operation
    def initialize(item:, warehouse:, quantity:, user:, reason: nil, on: Date.current)
      @item = item
      @warehouse = warehouse
      @quantity = quantity
      @user = user
      @reason = reason
      @on = on
    end

    def call
      quantity = positive_quantity(@quantity)

      StockMovement.transaction do
        lots = @item.lots.usable_on(@on).fefo.lock.to_a
        balances = StockMovement.balances(warehouse: @warehouse, lots: lots)

        Allocation.new(lots: lots, balances: balances, quantity: quantity).lines.map do |line|
          StockMovement.create!(
            lot: line.lot, warehouse: @warehouse, user: @user, reason: @reason,
            kind: :issue, quantity: -line.quantity
          )
        end
      end
    end
  end
end
