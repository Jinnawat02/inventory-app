class Item < ApplicationRecord
  SKU_FORMAT = /\A[A-Z0-9-]+\z/

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  normalizes :sku, with: ->(sku) { sku.strip.upcase }
  normalizes :name, :unit, with: ->(value) { value.strip }

  validates :name, :unit, presence: true
  validates :sku, presence: true, uniqueness: true, format: { with: SKU_FORMAT }
  validates :quantity, :low_stock_threshold, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def low_stock?
    quantity <= low_stock_threshold
  end
end
