class Warehouse < ApplicationRecord
  normalizes :code, with: ->(code) { code.strip.upcase }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, length: { maximum: 10 }
end
