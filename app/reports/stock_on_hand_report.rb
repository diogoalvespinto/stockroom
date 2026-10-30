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
    build(in_display_order.pluck("stock_movements.warehouse_id", "stock_movements.lot_id", "stock_movements.quantity"))
  end

  private
    def balances
      scope = StockMovement.group(:warehouse_id, :lot_id).having("SUM(quantity) > 0")
      scope = scope.where(warehouse: @warehouse) if @warehouse
      scope = scope.where(lot: @lots) if @lots
      scope
    end

    def in_display_order
      StockMovement
        .from(balances.select(:warehouse_id, :lot_id, "SUM(quantity) AS quantity"), :stock_movements)
        .joins(:warehouse, lot: :item)
        .order("warehouses.code", "items.sku")
        .merge(Lot.fefo)
    end

    def build(sums)
      warehouses = Warehouse.where(id: sums.map(&:first)).index_by(&:id)
      lots = Lot.includes(:item).where(id: sums.map(&:second)).index_by(&:id)

      sums.map do |warehouse_id, lot_id, quantity|
        Row.new(warehouse: warehouses.fetch(warehouse_id), lot: lots.fetch(lot_id), quantity: quantity)
      end
    end
end
