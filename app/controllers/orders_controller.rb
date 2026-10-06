class OrdersController < ApplicationController
  before_action :set_order, only: %i[show edit update]
  before_action :require_editable, only: %i[edit update]

  def index
    @orders = Current.user.orders.newest_first
  end

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

  def edit
  end

  def update
    if @order.update(order_params)
      redirect_to @order, notice: "บันทึกใบเบิกเรียบร้อยแล้ว"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_order
      @order = Current.user.orders.find(params[:id])
    end

    def require_editable
      redirect_to @order, alert: "แก้ไขได้เฉพาะใบเบิกที่รออนุมัติ" unless @order.editable?
    end

    def order_params
      params.expect(order: [ :purpose, order_items_attributes: [ [ :id, :item_id, :quantity, :_destroy ] ] ])
    end
end
