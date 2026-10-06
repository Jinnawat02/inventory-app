class StockAdjustment
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :change, :integer

  attr_reader :item

  validates :change, numericality: { only_integer: true, other_than: 0 }
  validate :resulting_quantity_not_negative

  def initialize(item:, **attributes)
    @item = item
    super(**attributes)
  end

  def change_before_type_cast
    @attributes["change"].value_before_type_cast
  end

  def save
    return false unless valid?

    item.with_lock do
      item.update!(quantity: item.quantity + change)
    end
    true
  rescue ActiveRecord::RecordInvalid
    errors.add(:change, :insufficient_stock)
    false
  end

  private
    def resulting_quantity_not_negative
      return if change.nil?

      errors.add(:change, :insufficient_stock) if item.quantity + change < 0
    end
end
