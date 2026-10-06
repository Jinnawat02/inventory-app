require "test_helper"

class Admin::Orders::ApprovalsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "approve a pending order" do
    post admin_order_approval_path(orders(:pending_one))

    assert_redirected_to admin_order_path(orders(:pending_one))
    assert orders(:pending_one).reload.approved?
    assert_equal users(:admin), orders(:pending_one).decided_by
  end

  test "cannot approve an order that is not pending" do
    post admin_order_approval_path(orders(:rejected_two))

    assert_redirected_to admin_order_path(orders(:rejected_two))
    assert_match "ไม่สามารถดำเนินการได้", flash[:alert]
    assert orders(:rejected_two).reload.rejected?
  end

  test "users cannot approve" do
    sign_in_as users(:one)

    post admin_order_approval_path(orders(:pending_one))

    assert_redirected_to root_path
    assert orders(:pending_one).reload.pending?
  end
end
