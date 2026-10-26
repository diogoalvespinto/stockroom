class BelowReorderLevelReport
  Row = Data.define(:item, :usable_quantity) do
    def shortfall
      item.reorder_level - usable_quantity
    end
  end

  def initialize(on: Date.current)
    @on = on
  end

  def rows
    usable = StockMovement.joins(:lot).merge(Lot.usable_on(@on)).group("lots.item_id").sum(:quantity)

    Item.where(reorder_level: 1..)
      .map { |item| Row.new(item: item, usable_quantity: usable.fetch(item.id, 0)) }
      .select { |row| row.shortfall.positive? }
      .sort_by { |row| [ -row.shortfall, row.item.sku ] }
  end
end
