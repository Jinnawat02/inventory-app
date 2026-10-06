require "test_helper"

class Admin::Orders::FulfillmentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "fulfill an approved order" do
    post admin_order_fulfillment_path(orders(:approved_one))

    assert_redirected_to admin_order_path(orders(:approved_one))
    assert orders(:approved_one).reload.fulfilled?
    assert orders(:approved_one).fulfilled_at
    assert_enqueued_email_with OrderMailer, :status_changed, args: [ orders(:approved_one), "fulfilled" ]
  end

  test "cannot fulfill a pending order" do
    post admin_order_fulfillment_path(orders(:pending_one))

    assert_redirected_to admin_order_path(orders(:pending_one))
    assert_match "ไม่สามารถดำเนินการได้", flash[:alert]
    assert orders(:pending_one).reload.pending?
  end

  test "users cannot fulfill" do
    sign_in_as users(:one)

    post admin_order_fulfillment_path(orders(:approved_one))

    assert_redirected_to root_path
    assert orders(:approved_one).reload.approved?
  end

  test "fulfilled order shows the fulfillment timestamp" do
    post admin_order_fulfillment_path(orders(:approved_one))
    follow_redirect!

    assert_select "#order_status .order-status", "จ่ายของแล้ว"
    assert_select "#order_fulfilled_at", I18n.l(orders(:approved_one).reload.fulfilled_at)
  end
end
