class Admin::Orders::BaseController < Admin::BaseController
  before_action :set_order

  rescue_from Order::InvalidTransition do
    redirect_to admin_order_path(@order), alert: "ไม่สามารถดำเนินการได้ในสถานะปัจจุบัน (#{@order.reload.status_name})"
  end

  private
    def set_order
      @order = Order.find(params[:order_id])
    end
end
