class Warehouse < ApplicationRecord
  has_many :stock_movements, dependent: :restrict_with_error

  normalizes :code, with: ->(code) { code.strip.upcase }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, length: { maximum: 10 }
end
