class StockOnHandReport
  PER_PAGE = 50

  Row = Data.define(:warehouse, :lot, :quantity) do
    def item
      lot.item
    end
  end

  Page = Data.define(:rows, :number, :last) do
    alias_method :last?, :last

    def first?
      number == 1
    end
  end

  CursorPage = Data.define(:rows, :last) do
    alias_method :last?, :last

    def next_after
      [ rows.last.warehouse.id, rows.last.lot.id ] unless last?
    end
  end

  def initialize(warehouse: nil, lots: nil)
    @warehouse = warehouse
    @lots = lots
  end

  def rows
    build(sums(in_display_order))
  end

  def page(number, per: PER_PAGE)
    found = build(sums(in_display_order.limit(per + 1).offset((number - 1) * per)))

    Page.new(rows: found.first(per), number: number, last: found.size <= per)
  end

  def after(position, per: PER_PAGE)
    scope = balances.order(:warehouse_id, :lot_id).limit(per + 1)
    scope = scope.where("(stock_movements.warehouse_id, stock_movements.lot_id) > (?, ?)", *position) if position
    found = build(scope.pluck(:warehouse_id, :lot_id, "SUM(quantity)"))

    CursorPage.new(rows: found.first(per), last: found.size <= per)
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

    def sums(scope)
      scope.pluck("stock_movements.warehouse_id", "stock_movements.lot_id", "stock_movements.quantity")
    end

    def build(sums)
      warehouses = Warehouse.where(id: sums.map(&:first)).index_by(&:id)
      lots = Lot.includes(:item).where(id: sums.map(&:second)).index_by(&:id)

      sums.map do |warehouse_id, lot_id, quantity|
        Row.new(warehouse: warehouses.fetch(warehouse_id), lot: lots.fetch(lot_id), quantity: quantity)
      end
    end
end
