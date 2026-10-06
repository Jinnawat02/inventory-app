class Admin::Orders::ApprovalsController < Admin::Orders::BaseController
  def create
    @order.approve!(by: Current.user)
    redirect_to admin_order_path(@order), notice: "อนุมัติใบเบิกเรียบร้อยแล้ว"
  end
end
