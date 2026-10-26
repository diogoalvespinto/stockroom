module Stock
  class Operation
    def self.call(...)
      new(...).call
    end

    private
      def positive_quantity(value)
        quantity = Integer(value.to_s, exception: false)
        raise InvalidRequest, "Quantity must be a positive whole number" unless quantity&.positive?

        quantity
      end
  end
end
