require "test_helper"

class Admin::Orders::FulfillmentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "fulfill an approved order" do
    post admin_order_fulfillment_path(orders(:approved_one))

    assert_redirected_to admin_order_path(orders(:approved_one))
    assert orders(:approved_one).reload.fulfilled?
    assert orders(:approved_one).fulfilled_at
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
end
