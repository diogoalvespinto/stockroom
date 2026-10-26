class StockOnHandReport
  Row = Data.define(:warehouse, :lot, :quantity) do
    def item
      lot.item
    end
  end

  def initialize(warehouse: nil, lots: nil)
    @warehouse = warehouse
    @lots = lots
  end

  def rows
    balances = movements.group(:warehouse_id, :lot_id).having("SUM(quantity) > 0").sum(:quantity)
    warehouses = Warehouse.where(id: balances.keys.map(&:first)).index_by(&:id)
    lots = Lot.includes(:item).where(id: balances.keys.map(&:last)).index_by(&:id)

    balances
      .map { |(warehouse_id, lot_id), quantity| Row.new(warehouse: warehouses.fetch(warehouse_id), lot: lots.fetch(lot_id), quantity: quantity) }
      .sort_by { |row| [ row.warehouse.code, row.item.sku, row.lot.expiry_date ? 0 : 1, row.lot.expiry_date.to_s, row.lot.id ] }
  end

  private
    def movements
      scope = StockMovement.all
      scope = scope.where(warehouse: @warehouse) if @warehouse
      scope = scope.where(lot: @lots) if @lots
      scope
    end
end
