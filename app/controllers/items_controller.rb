class ItemsController < ApplicationController
  include ItemFiltering

  def index
    @items = Item.active.ordered.filter_by(**item_filters)
  end

  def show
    @item = visible_items.find(params[:id])
  end

  private
    def visible_items
      Current.user.admin? ? Item.all : Item.active
    end
end
