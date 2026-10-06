require "test_helper"

class Admin::Orders::ApprovalsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "approve a pending order" do
    post admin_order_approval_path(orders(:pending_one))

    assert_redirected_to admin_order_path(orders(:pending_one))
    assert orders(:pending_one).reload.approved?
    assert_equal users(:admin), orders(:pending_one).decided_by
    assert_enqueued_email_with OrderMailer, :status_changed, args: [ orders(:pending_one), "approved" ]
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

  test "approval deducts stock" do
    assert_difference -> { items(:paper).reload.quantity }, -5 do
      post admin_order_approval_path(orders(:pending_one))
    end
  end

  test "approval is refused when stock is insufficient and lists the short items" do
    order_items(:pending_two_toner).update!(quantity: 3)

    assert_no_difference -> { items(:toner).reload.quantity } do
      post admin_order_approval_path(orders(:pending_two))
    end

    assert_redirected_to admin_order_path(orders(:pending_two))
    assert_equal "อนุมัติไม่ได้ สต็อกไม่พอ: ผงหมึกเครื่องพิมพ์ (ขอ 3 คงเหลือ 2 กล่อง)", flash[:alert]
    assert orders(:pending_two).reload.pending?
  end
end
