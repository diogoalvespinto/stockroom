module Stock
  class Operation
    def self.call(...)
      new(...).call
    end

    private
      def whole_number(value)
        Integer(value.to_s, exception: false)
      end

      def positive_quantity(value)
        quantity = whole_number(value)
        raise InvalidRequest, "Quantity must be a positive whole number" unless quantity&.positive?

        quantity
      end

      def reserve(lot, warehouse, quantity)
        lot.lock!
        available = StockMovement.balance(warehouse: warehouse, lot: lot)
        raise InsufficientStock.new(requested: quantity, available: available) if available < quantity
      end
  end
end
