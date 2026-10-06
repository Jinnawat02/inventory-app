require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  test "new_request goes to every active admin with the request details" do
    other_admin = User.create!(name: "แอดมินสอง", email_address: "admin2@example.com", password: "password", role: "admin")
    User.create!(name: "แอดมินพัก", email_address: "admin3@example.com", password: "password", role: "admin", active: false)
    order = orders(:pending_one)

    email = OrderMailer.new_request(order)

    assert_emails(1) { email.deliver_now }
    assert_equal [ users(:admin).email_address, other_admin.email_address ].sort, email.to.sort
    assert_equal "ใบเบิกใหม่ ##{order.id} จาก #{users(:one).name}", email.subject

    [ email.html_part.decoded, email.text_part.decoded ].each do |body|
      assert_includes body, users(:one).name
      assert_includes body, order.purpose
      assert_includes body, items(:paper).name
      assert_includes body, "5 รีม"
      assert_includes body, items(:pen).name
      assert_includes body, "10 ด้าม"
      assert_includes body, "http://example.com/admin/orders/#{order.id}"
    end
  end

  test "new_request is not sent when there are no active admins" do
    users(:admin).update_column(:active, false)

    email = OrderMailer.new_request(orders(:pending_one))

    assert_no_emails { email.deliver_now }
  end
end
