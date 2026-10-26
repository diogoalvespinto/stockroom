class StockRowSerializer
  def initialize(row, days_left: nil)
    @row = row
    @days_left = days_left
  end

  def as_json(*)
    {
      warehouse_id: @row.warehouse.id,
      item_id: @row.item.id,
      lot: LotSerializer.new(@row.lot).as_json,
      quantity: @row.quantity,
      days_left: @days_left
    }.compact
  end
end
