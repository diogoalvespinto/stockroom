module Stock
  class Error < StandardError; end

  class InvalidRequest < Error; end

  class InsufficientStock < Error
    attr_reader :requested, :available

    def initialize(requested:, available:)
      @requested = requested
      @available = available
      super("Requested #{requested} but only #{available} available")
    end
  end

  class ExpiryMismatch < Error
    def initialize(lot)
      super("Lot #{lot.lot_number} already exists with expiry date #{lot.expiry_date || "none"}")
    end
  end

  class SameWarehouse < Error
    def initialize
      super("Source and destination warehouses must be different")
    end
  end
end
