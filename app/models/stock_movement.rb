class StockMovement < ApplicationRecord
  belongs_to :lot
  belongs_to :warehouse
  belongs_to :user

  enum :kind, {
    receipt: "receipt",
    issue: "issue",
    transfer_out: "transfer_out",
    transfer_in: "transfer_in",
    adjustment: "adjustment"
  }, validate: true

  validates :quantity, numericality: { only_integer: true, other_than: 0 }
  validates :quantity, numericality: { greater_than: 0 }, if: -> { receipt? || transfer_in? }
  validates :quantity, numericality: { less_than: 0 }, if: -> { issue? || transfer_out? }
  validates :reason, presence: true, if: :adjustment?

  def readonly?
    persisted? || super
  end
end
