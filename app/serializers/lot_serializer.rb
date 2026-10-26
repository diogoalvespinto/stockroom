class LotSerializer
  def initialize(lot)
    @lot = lot
  end

  def as_json(*)
    { id: @lot.id, item_id: @lot.item_id, lot_number: @lot.lot_number, expiry_date: @lot.expiry_date&.iso8601 }
  end
end
