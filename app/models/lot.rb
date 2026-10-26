class Lot < ApplicationRecord
  belongs_to :item

  normalizes :lot_number, with: ->(lot_number) { lot_number.strip.upcase }

  validates :lot_number, presence: true, uniqueness: { scope: :item_id }

  def expired?(on: Date.current)
    expiry_date.present? && expiry_date < on
  end
end
