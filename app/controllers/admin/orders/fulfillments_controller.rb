class Admin::Orders::FulfillmentsController < Admin::Orders::BaseController
  def create
    @order.fulfill!
    redirect_to admin_order_path(@order), notice: "บันทึกการจ่ายของเรียบร้อยแล้ว"
  end
end
