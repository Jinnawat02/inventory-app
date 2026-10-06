class Admin::Orders::ApprovalsController < Admin::Orders::BaseController
  def create
    @order.approve!(by: Current.user)
    redirect_to admin_order_path(@order), notice: "อนุมัติใบเบิกและตัดสต็อกเรียบร้อยแล้ว"
  rescue Order::InsufficientStock => error
    redirect_to admin_order_path(@order), alert: "อนุมัติไม่ได้ สต็อกไม่พอ: #{shortage_summary(error.shortages)}"
  end

  private
    def shortage_summary(shortages)
      shortages.map { |shortage|
        "#{shortage.item.name} (ขอ #{shortage.requested} คงเหลือ #{shortage.available} #{shortage.item.unit})"
      }.join(", ")
    end
end
