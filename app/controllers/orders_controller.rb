class OrdersController < ApplicationController
  before_action :set_order, only: :show

  def show
  end

  def new
    @order = Current.user.orders.new
    @order.order_items.build
  end

  def create
    @order = Current.user.orders.new(order_params)

    if @order.save
      redirect_to @order, notice: "ส่งใบเบิกเรียบร้อยแล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_order
      @order = Current.user.orders.find(params[:id])
    end

    def order_params
      params.expect(order: [ :purpose, order_items_attributes: [ [ :id, :item_id, :quantity, :_destroy ] ] ])
    end
end
