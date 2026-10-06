require "test_helper"

class OrderLifecycleTest < ActionDispatch::IntegrationTest
  test "a user's order is approved, deducted and fulfilled by an admin" do
    sign_in_as users(:one)
    post orders_path, params: { order: { purpose: "อบรมพนักงาน", order_items_attributes: {
      "0" => { item_id: items(:paper).id, quantity: "4" }
    } } }
    order = Order.last
    assert order.pending?

    sign_in_as users(:admin)
    assert_difference -> { items(:paper).reload.quantity }, -4 do
      post admin_order_approval_path(order)
    end
    post admin_order_fulfillment_path(order)
    assert order.reload.fulfilled?

    sign_in_as users(:one)
    post order_cancellation_path(order)
    assert_equal "ยกเลิกได้เฉพาะใบเบิกที่รออนุมัติ", flash[:alert]
    assert order.reload.fulfilled?
  end

  test "an admin can approve their own order" do
    sign_in_as users(:admin)
    post orders_path, params: { order: { purpose: "ใช้เอง", order_items_attributes: { "0" => { item_id: items(:pen).id, quantity: "2" } } } }
    order = users(:admin).orders.last

    post admin_order_approval_path(order)

    assert order.reload.approved?
    assert_equal users(:admin), order.decided_by
  end

  test "signed out visitors cannot reach any order page" do
    order = orders(:pending_one)

    [
      -> { get orders_path },
      -> { get order_path(order) },
      -> { post order_cancellation_path(order) },
      -> { get admin_orders_path },
      -> { get admin_order_path(order) },
      -> { post admin_order_approval_path(order) },
      -> { post admin_order_rejection_path(order), params: { order: { admin_note: "x" } } },
      -> { post admin_order_fulfillment_path(order) }
    ].each do |request|
      request.call
      assert_redirected_to new_session_path
    end

    assert order.reload.pending?
  end

  test "unknown orders return not found" do
    sign_in_as users(:admin)

    get admin_order_path(id: 0)
    assert_response :not_found

    post admin_order_approval_path(order_id: 0)
    assert_response :not_found

    get order_path(id: 0)
    assert_response :not_found
  end
end
