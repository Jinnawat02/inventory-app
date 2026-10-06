require "test_helper"

class Admin::Orders::RejectionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "new shows the reason form" do
    get new_admin_order_rejection_path(orders(:pending_one))

    assert_response :success
    assert_select "textarea[name='order[admin_note]']"
  end

  test "new redirects when the order cannot be rejected" do
    get new_admin_order_rejection_path(orders(:approved_one))

    assert_redirected_to admin_order_path(orders(:approved_one))
  end

  test "reject with a reason" do
    post admin_order_rejection_path(orders(:pending_one)), params: { order: { admin_note: "ยังมีของเหลือในแผนก" } }

    assert_redirected_to admin_order_path(orders(:pending_one))
    orders(:pending_one).reload.then do |order|
      assert order.rejected?
      assert_equal "ยังมีของเหลือในแผนก", order.admin_note
      assert_enqueued_email_with OrderMailer, :status_changed, args: [ order, "rejected" ]
    end
  end

  test "reject requires a reason" do
    post admin_order_rejection_path(orders(:pending_one)), params: { order: { admin_note: "" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /หมายเหตุจากผู้ดูแล/
    assert orders(:pending_one).reload.pending?
  end

  test "cannot reject an approved order" do
    post admin_order_rejection_path(orders(:approved_one)), params: { order: { admin_note: "เปลี่ยนใจ" } }

    assert_redirected_to admin_order_path(orders(:approved_one))
    assert orders(:approved_one).reload.approved?
  end

  test "users cannot reject" do
    sign_in_as users(:one)

    get new_admin_order_rejection_path(orders(:pending_two))
    assert_redirected_to root_path

    post admin_order_rejection_path(orders(:pending_two)), params: { order: { admin_note: "x" } }
    assert_redirected_to root_path
    assert orders(:pending_two).reload.pending?
  end
end
