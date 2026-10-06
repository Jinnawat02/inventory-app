require "test_helper"

class Orders::CancellationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "cancel my pending order" do
    post order_cancellation_path(orders(:pending_one))

    assert_redirected_to order_path(orders(:pending_one))
    assert orders(:pending_one).reload.cancelled?
  end

  test "cannot cancel an order that is no longer pending" do
    post order_cancellation_path(orders(:approved_one))

    assert_redirected_to order_path(orders(:approved_one))
    assert_equal "ยกเลิกได้เฉพาะใบเบิกที่รออนุมัติ", flash[:alert]
    assert orders(:approved_one).reload.approved?
  end

  test "cannot cancel another user's order" do
    post order_cancellation_path(orders(:pending_two))

    assert_response :not_found
    assert orders(:pending_two).reload.pending?
  end

  test "admins cannot cancel other users' orders through this route" do
    sign_in_as users(:admin)

    post order_cancellation_path(orders(:pending_one))

    assert_response :not_found
    assert orders(:pending_one).reload.pending?
  end
end
