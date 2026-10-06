class Orders::CancellationsController < ApplicationController
  def create
    order = Current.user.orders.find(params[:order_id])
    order.cancel!
    redirect_to order, notice: "ยกเลิกใบเบิกเรียบร้อยแล้ว"
  rescue Order::InvalidTransition
    redirect_to order, alert: "ยกเลิกได้เฉพาะใบเบิกที่รออนุมัติ"
  end
end
