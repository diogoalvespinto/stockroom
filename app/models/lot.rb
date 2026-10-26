class Lot < ApplicationRecord
  belongs_to :item
  has_many :stock_movements, dependent: :restrict_with_error

  normalizes :lot_number, with: ->(lot_number) { lot_number.strip.upcase }

  validates :lot_number, presence: true, uniqueness: { scope: :item_id }

  scope :usable_on, ->(date) { where(expiry_date: nil).or(where(expiry_date: date..)) }
  scope :fefo, -> { order(arel_table[:expiry_date].asc.nulls_last, :id) }

  def expired?(on: Date.current)
    expiry_date.present? && expiry_date < on
  end
end
