class ItemSerializer
  def initialize(item)
    @item = item
  end

  def as_json(*)
    {
      id: @item.id,
      sku: @item.sku,
      name: @item.name,
      unit_of_measure: @item.unit_of_measure,
      reorder_level: @item.reorder_level
    }
  end
end
