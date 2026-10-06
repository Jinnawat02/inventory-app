class OrderMailer < ApplicationMailer
  def new_request(order)
    @order = order
    recipients = User.active.admin.pluck(:email_address)
    return if recipients.empty?

    mail to: recipients, subject: "ใบเบิกใหม่ ##{order.id} จาก #{order.user.name}"
  end
end
