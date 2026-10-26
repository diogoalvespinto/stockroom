module Stock
  class Allocation
    Line = Data.define(:lot, :quantity)

    def initialize(lots:, balances:, quantity:)
      @lots = lots
      @balances = balances
      @quantity = quantity
    end

    def lines
      remaining = @quantity

      lines = @lots.filter_map do |lot|
        take = [ @balances.fetch(lot.id, 0), remaining ].min
        next unless take.positive?

        remaining -= take
        Line.new(lot: lot, quantity: take)
      end
      raise InsufficientStock.new(requested: @quantity, available: @quantity - remaining) if remaining.positive?

      lines
    end
  end
end
