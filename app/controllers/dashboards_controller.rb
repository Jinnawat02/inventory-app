class DashboardsController < ApplicationController
  LOW_STOCK_LIMIT = 10

  before_action :require_admin

  def show
    @active_items_count = Item.active.count
    @low_stock_items_count = Item.active.low_stock.count
    @inactive_items_count = Item.inactive.count
    @active_users_by_role = active_users_by_role
    @low_stock_items = Item.active.low_stock.by_quantity.limit(LOW_STOCK_LIMIT)
  end

  private
    def active_users_by_role
      counts = User.active.group(:role).count
      User.roles.keys.index_with { |role| counts.fetch(role, 0) }
    end
end
