class OrderItem < ApplicationRecord
  belongs_to :order, inverse_of: :order_items
  belongs_to :item

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :item_id, uniqueness: { scope: :order_id }, allow_nil: true
  validate :item_is_active, if: -> { item && (new_record? || will_save_change_to_item_id?) }

  private
    def item_is_active
      errors.add(:item, :inactive) unless item.active?
    end
end
