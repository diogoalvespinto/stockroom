class Lot < ApplicationRecord
  belongs_to :item
  has_many :stock_movements, dependent: :restrict_with_error

  normalizes :lot_number, with: ->(lot_number) { lot_number.strip.upcase }

  validates :lot_number, presence: true, uniqueness: { scope: :item_id }

  def expired?(on: Date.current)
    expiry_date.present? && expiry_date < on
  end
end
