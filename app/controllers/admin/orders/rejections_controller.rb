class Admin::Orders::RejectionsController < Admin::Orders::BaseController
  def new
    raise Order::InvalidTransition unless @order.can_transition_to?(:rejected)
  end

  def create
    @order.reject!(by: Current.user, note: params.expect(order: [ :admin_note ])[:admin_note])
    redirect_to admin_order_path(@order), notice: "ไม่อนุมัติใบเบิกเรียบร้อยแล้ว"
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end
end
