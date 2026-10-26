class WarehouseSerializer
  def initialize(warehouse)
    @warehouse = warehouse
  end

  def as_json(*)
    { id: @warehouse.id, code: @warehouse.code, name: @warehouse.name }
  end
end
