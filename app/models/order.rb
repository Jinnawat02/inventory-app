class Order < ApplicationRecord
  belongs_to :user
  belongs_to :decided_by, class_name: "User", optional: true
  has_many :order_items, -> { order(:id) }, dependent: :destroy, inverse_of: :order
  has_many :items, through: :order_items

  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected",
    cancelled: "cancelled",
    fulfilled: "fulfilled"
  }, default: "pending", validate: true

  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: :blank_line?

  normalizes :purpose, with: ->(purpose) { purpose.strip }

  validates :purpose, presence: true
  validate :has_at_least_one_line
  validate :items_listed_once

  def status_name
    self.class.status_name(status)
  end

  def self.status_name(status)
    I18n.t("orders.statuses.#{status}")
  end

  private
    def blank_line?(attributes)
      attributes["id"].blank? && attributes["item_id"].blank? && attributes["quantity"].blank?
    end

    def kept_lines
      order_items.reject(&:marked_for_destruction?)
    end

    def has_at_least_one_line
      errors.add(:order_items, :too_short) if kept_lines.empty?
    end

    def items_listed_once
      item_ids = kept_lines.map(&:item_id).compact
      errors.add(:order_items, :duplicate_item) if item_ids.uniq.size != item_ids.size
    end
end
