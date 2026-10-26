class Item < ApplicationRecord
  has_many :lots, dependent: :restrict_with_error

  normalizes :sku, with: ->(sku) { sku.strip.upcase }

  validates :sku, presence: true, uniqueness: true
  validates :name, :unit_of_measure, presence: true
  validates :reorder_level, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
