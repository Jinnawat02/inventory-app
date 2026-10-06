class OrderMailerPreview < ActionMailer::Preview
  def new_request
    OrderMailer.new_request(sample_order(status: "pending"))
  end

  def status_changed_approved
    OrderMailer.status_changed(sample_order(status: "approved", decided_at: Time.current), "approved")
  end

  def status_changed_rejected
    order = sample_order(status: "rejected", decided_at: Time.current, admin_note: "ยังมีของเหลือในแผนก กรุณาใช้ของเดิมก่อน")
    OrderMailer.status_changed(order, "rejected")
  end

  def status_changed_fulfilled
    OrderMailer.status_changed(sample_order(status: "fulfilled", decided_at: 1.day.ago, fulfilled_at: Time.current), "fulfilled")
  end

  private
    def sample_order(**attributes)
      requester = User.new(id: 1, name: "สมชาย ใจดี", email_address: "somchai@example.com")
      order = Order.new(id: 1, user: requester, purpose: "ใช้ในการประชุมประจำเดือน", created_at: Time.current, **attributes)
      order.order_items.build(item: Item.new(name: "กระดาษ A4 80 แกรม", sku: "PAPER-A4", unit: "รีม"), quantity: 5)
      order.order_items.build(item: Item.new(name: "ปากกาลูกลื่น สีน้ำเงิน", sku: "PEN-BLUE", unit: "ด้าม"), quantity: 10)
      order
    end
end
