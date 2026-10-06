class Order < ApplicationRecord
  class InvalidTransition < StandardError; end

  Shortage = Data.define(:item, :requested, :available)

  class InsufficientStock < StandardError
    attr_reader :shortages

    def initialize(shortages)
      @shortages = shortages
      super("insufficient stock for #{shortages.map { |shortage| shortage.item.sku }.join(", ")}")
    end
  end

  TRANSITIONS = {
    "pending" => %w[approved rejected cancelled],
    "approved" => %w[fulfilled]
  }.freeze

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

  normalizes :purpose, :admin_note, with: ->(text) { text.strip }

  validates :purpose, presence: true
  validates :admin_note, presence: true, if: :rejected?
  validate :has_at_least_one_line
  validate :items_listed_once
  validate :status_change_allowed, on: :update, if: :will_save_change_to_status?
  validate :lines_editable_only_while_pending, on: :update

  after_create_commit :notify_admins_of_new_request

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :admin_queue, -> {
    order(
      Arel.sql("CASE WHEN orders.status = 'pending' THEN 0 ELSE 1 END"),
      Arel.sql("CASE WHEN orders.status = 'pending' THEN orders.created_at END ASC"),
      created_at: :desc,
      id: :desc
    )
  }
  scope :with_status, ->(status) { statuses.key?(status.to_s) ? where(status: status) : all }

  def can_transition_to?(new_status)
    TRANSITIONS.fetch(status, []).include?(new_status.to_s)
  end

  def editable?
    persisted? && status_in_database == "pending"
  end

  def approve!(by:)
    transition_to!(:approved, decided_by: by, decided_at: Time.current) { deduct_stock! }
  end

  def reject!(by:, note:)
    transition_to!(:rejected, decided_by: by, decided_at: Time.current, admin_note: note)
  end

  def fulfill!
    transition_to!(:fulfilled, fulfilled_at: Time.current)
  end

  def cancel!
    transition_to!(:cancelled)
  end

  def status_name
    self.class.status_name(status)
  end

  def self.status_name(status)
    I18n.t("orders.statuses.#{status}")
  end

  private
    def transition_to!(new_status, **attributes)
      with_lock do
        raise InvalidTransition, "cannot change order #{id} from #{status} to #{new_status}" unless can_transition_to?(new_status)

        yield if block_given?
        update!(status: new_status, **attributes)
      end
    end

    def notify_admins_of_new_request
      OrderMailer.new_request(self).deliver_later
    end

    def deduct_stock!
      lines = order_items.to_a
      locked_items = Item.where(id: lines.map(&:item_id)).order(:id).lock.index_by(&:id)

      shortages = lines.filter_map do |line|
        item = locked_items.fetch(line.item_id)
        Shortage.new(item: item, requested: line.quantity, available: item.quantity) if item.quantity < line.quantity
      end
      raise InsufficientStock.new(shortages) if shortages.any?

      lines.each do |line|
        item = locked_items.fetch(line.item_id)
        item.update!(quantity: item.quantity - line.quantity)
      end
    end

    def blank_line?(attributes)
      attributes["id"].blank? && attributes["item_id"].blank? && attributes["quantity"].blank?
    end

    def kept_lines
      order_items.reject(&:marked_for_destruction?)
    end

    def has_at_least_one_line
      errors.add(:order_items, :too_short) if kept_lines.empty?
    end

    def status_change_allowed
      allowed = TRANSITIONS.fetch(status_in_database, [])
      errors.add(:status, :invalid_transition) unless allowed.include?(status)
    end

    def lines_editable_only_while_pending
      return if status_in_database == "pending"

      changed_lines = order_items.any? { |line| line.new_record? || line.changed? || line.marked_for_destruction? }
      errors.add(:order_items, :locked) if changed_lines || will_save_change_to_purpose?
    end

    def items_listed_once
      item_ids = kept_lines.map(&:item_id).compact
      errors.add(:order_items, :duplicate_item) if item_ids.uniq.size != item_ids.size
    end
end
