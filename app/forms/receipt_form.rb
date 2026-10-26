class ReceiptForm < StockForm
  attribute :item_id, :integer
  attribute :warehouse_id, :integer
  attribute :lot_number, :string
  attribute :expiry_date, :string
  attribute :quantity, :string

  validates :item_id, :warehouse_id, :lot_number, :quantity, presence: true

  attr_reader :movement

  def self.model_name
    ActiveModel::Name.new(self, nil, "Receipt")
  end

  def save(user:)
    perform do
      @movement = Stock::Receive.call(
        item: Item.find(item_id), warehouse: Warehouse.find(warehouse_id),
        lot_number: lot_number, expiry_date: expiry_date, quantity: quantity, user: user
      )
    end
  end

  def summary
    item = movement.lot.item
    "Received #{movement.quantity} #{item.unit_of_measure} of #{item.sku} into #{movement.warehouse.code} (lot #{movement.lot.lot_number})"
  end
end
