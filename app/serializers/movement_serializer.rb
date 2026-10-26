class MovementSerializer
  def initialize(movement)
    @movement = movement
  end

  def as_json(*)
    {
      id: @movement.id,
      kind: @movement.kind,
      quantity: @movement.quantity,
      warehouse_id: @movement.warehouse_id,
      lot: LotSerializer.new(@movement.lot).as_json,
      transfer_id: @movement.transfer_id,
      reason: @movement.reason,
      user_id: @movement.user_id,
      created_at: @movement.created_at.iso8601(3)
    }
  end
end
