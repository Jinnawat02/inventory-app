class Item < ApplicationRecord
  SKU_FORMAT = /\A[A-Z0-9-]+\z/

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :low_stock, -> { where(arel_table[:quantity].lteq(arel_table[:low_stock_threshold])) }
  scope :search, ->(term) {
    pattern = "%#{sanitize_sql_like(term.to_s.strip)}%"
    where(arel_table[:name].matches(pattern, "\\")).or(where(arel_table[:sku].matches(pattern, "\\")))
  }

  normalizes :sku, with: ->(sku) { sku.strip.upcase }
  normalizes :name, :unit, with: ->(value) { value.strip }

  validates :name, :unit, presence: true
  validates :sku, presence: true, uniqueness: true, format: { with: SKU_FORMAT }
  validates :quantity, :low_stock_threshold, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.filter_by(query: nil, low_stock: false)
    items = all
    items = items.search(query) if query.present?
    items = items.low_stock if low_stock
    items
  end

  def low_stock?
    quantity <= low_stock_threshold
  end
end
