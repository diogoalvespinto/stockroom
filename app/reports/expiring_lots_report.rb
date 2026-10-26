class ExpiringLotsReport
  WINDOWS = [ 7, 14, 30, 60, 90 ].freeze
  DEFAULT_WINDOW = 30

  attr_reader :within_days, :on

  def initialize(within_days: DEFAULT_WINDOW, on: Date.current, warehouse: nil)
    @within_days = within_days
    @on = on
    @warehouse = warehouse
  end

  def rows
    lots = Lot.where(expiry_date: on..(on + within_days))

    StockOnHandReport.new(warehouse: @warehouse, lots: lots).rows
      .sort_by { |row| [ row.lot.expiry_date, row.warehouse.code, row.item.sku ] }
  end

  def days_left(lot)
    (lot.expiry_date - on).to_i
  end
end
