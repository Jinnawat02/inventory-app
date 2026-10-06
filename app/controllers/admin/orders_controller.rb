class Admin::OrdersController < Admin::BaseController
  def index
    @status = params[:status].presence_in(Order.statuses.keys)
    @orders = Order.includes(:user).with_status(@status).admin_queue
  end

  def show
    @order = Order.find(params[:id])
  end
end
