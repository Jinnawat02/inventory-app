class OrderMailer < ApplicationMailer
  def new_request(order)
    @order = order
    recipients = User.active.admin.pluck(:email_address)
    return if recipients.empty?

    mail to: recipients, subject: "ใบเบิกใหม่ ##{order.id} จาก #{order.user.name}"
  end

  def status_changed(order, status)
    @order = order
    @status = status

    mail to: order.user.email_address, subject: "ใบเบิก ##{order.id} #{Order.status_name(status)}"
  end
end
