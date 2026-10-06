require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "new renders the form with one line and only active items" do
    get new_order_path

    assert_response :success
    assert_select "#order_lines [data-nested-form-row]", 1
    assert_select "#order_lines option[value='#{items(:paper).id}']"
    assert_select "#order_lines option[value='#{items(:retired).id}']", 0
    assert_select "template[data-nested-form-target='template']"
  end

  test "create an order with multiple lines" do
    assert_difference -> { Order.count } => 1, -> { OrderItem.count } => 2 do
      post orders_path, params: { order: { purpose: "จัดประชุม", order_items_attributes: {
        "0" => { item_id: items(:paper).id, quantity: "2" },
        "1712345678" => { item_id: items(:pen).id, quantity: "5" }
      } } }
    end

    order = Order.last
    assert_redirected_to order_path(order)
    assert_equal users(:one), order.user
    assert order.pending?
    assert_equal({ items(:paper).id => 2, items(:pen).id => 5 }, order.order_items.to_h { |line| [ line.item_id, line.quantity ] })
  end

  test "create ignores attempts to set status or owner" do
    post orders_path, params: { order: { purpose: "ทดสอบ", status: "approved", user_id: users(:two).id, order_items_attributes: {
      "0" => { item_id: items(:paper).id, quantity: "1" }
    } } }

    order = Order.last
    assert order.pending?
    assert_equal users(:one), order.user
  end

  test "create without lines re-renders the form" do
    assert_no_difference -> { Order.count } do
      post orders_path, params: { order: { purpose: "ทดสอบ", order_items_attributes: { "0" => { item_id: "", quantity: "" } } } }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /ต้องมีอย่างน้อย 1 รายการ/
  end

  test "create with an inactive item is rejected" do
    assert_no_difference -> { Order.count } do
      post orders_path, params: { order: { purpose: "ทดสอบ", order_items_attributes: { "0" => { item_id: items(:retired).id, quantity: "1" } } } }
    end

    assert_response :unprocessable_entity
  end

  test "create with a duplicate item is rejected" do
    assert_no_difference -> { Order.count } do
      post orders_path, params: { order: { purpose: "ทดสอบ", order_items_attributes: {
        "0" => { item_id: items(:paper).id, quantity: "1" },
        "1" => { item_id: items(:paper).id, quantity: "2" }
      } } }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /มีพัสดุซ้ำกัน/
  end

  test "show own order" do
    get order_path(orders(:pending_one))

    assert_response :success
    assert_select "#order_items tbody tr", 2
  end

  test "requires sign in" do
    sign_out

    get new_order_path
    assert_redirected_to new_session_path
  end
end
