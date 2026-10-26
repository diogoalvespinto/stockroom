class IssueForm < StockForm
  attribute :item_id, :integer
  attribute :warehouse_id, :integer
  attribute :quantity, :string
  attribute :reason, :string

  validates :item_id, :warehouse_id, :quantity, presence: true

  attr_reader :movements

  def self.model_name
    ActiveModel::Name.new(self, nil, "Issue")
  end

  def save(user:)
    perform do
      @movements = Stock::Issue.call(
        item: Item.find(item_id), warehouse: Warehouse.find(warehouse_id),
        quantity: quantity, reason: reason.presence, user: user
      )
    end
  end

  def summary
    item = movements.first.lot.item
    lines = movements.map { |movement| "#{-movement.quantity} from lot #{movement.lot.lot_number}" }
    "Issued #{-movements.sum(&:quantity)} #{item.unit_of_measure} of #{item.sku}: #{lines.to_sentence}"
  end
end
