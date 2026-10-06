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
    assert_enqueued_email_with OrderMailer, :new_request, args: [ order ]
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
    assert_no_enqueued_emails do
      post orders_path, params: { order: { purpose: "ทดสอบ", order_items_attributes: { "0" => { item_id: "", quantity: "" } } } }
    end

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

  test "index lists only my orders, newest first" do
    get orders_path

    assert_response :success
    assert_select "#orders tbody tr", users(:one).orders.count
    assert_select "##{dom_id(orders(:pending_two))}", 0
    assert_select "#orders tbody tr:first-child##{dom_id(orders(:pending_one))}"
  end

  test "another user's order returns not found" do
    get order_path(orders(:pending_two))
    assert_response :not_found

    get edit_order_path(orders(:pending_two))
    assert_response :not_found

    patch order_path(orders(:pending_two)), params: { order: { purpose: "แอบแก้" } }
    assert_response :not_found
    assert_equal "เตรียมเอกสารอบรมพนักงานใหม่", orders(:pending_two).reload.purpose
  end

  test "admins also only see their own orders here" do
    sign_in_as users(:admin)

    get order_path(orders(:pending_one))

    assert_response :not_found
  end

  test "show offers edit and cancel only while pending" do
    get order_path(orders(:pending_one))
    assert_select "#owner_actions"

    get order_path(orders(:approved_one))
    assert_select "#owner_actions", 0
  end

  test "edit a pending order" do
    get edit_order_path(orders(:pending_one))

    assert_response :success
    assert_select "#order_lines [data-nested-form-row]", 2
  end

  test "update lines of a pending order" do
    order = orders(:pending_one)

    patch order_path(order), params: { order: { purpose: "ปรับรายการ", order_items_attributes: {
      "0" => { id: order_items(:pending_one_paper).id, item_id: items(:paper).id, quantity: "8" },
      "1" => { id: order_items(:pending_one_pen).id, item_id: items(:pen).id, quantity: "10", _destroy: "1" },
      "2" => { item_id: items(:toner).id, quantity: "1" }
    } } }

    assert_redirected_to order_path(order)
    assert_equal({ items(:paper).id => 8, items(:toner).id => 1 }, order.reload.order_items.to_h { |line| [ line.item_id, line.quantity ] })
  end

  test "update cannot hijack another order's line" do
    patch order_path(orders(:pending_one)), params: { order: { order_items_attributes: {
      "0" => { id: order_items(:pending_two_toner).id, quantity: "99" }
    } } }

    assert_response :not_found
    assert_equal 1, order_items(:pending_two_toner).reload.quantity
  end

  test "edit and update are refused once the order is decided" do
    get edit_order_path(orders(:approved_one))
    assert_redirected_to order_path(orders(:approved_one))
    assert_equal "แก้ไขได้เฉพาะใบเบิกที่รออนุมัติ", flash[:alert]

    patch order_path(orders(:approved_one)), params: { order: { purpose: "แก้" } }
    assert_redirected_to order_path(orders(:approved_one))
    assert_equal "ใช้พิมพ์รายงานประจำไตรมาส", orders(:approved_one).reload.purpose
  end

  test "show displays the status badge and decision timestamps" do
    order = orders(:approved_one)

    get order_path(order)

    assert_select "#order_status .order-status[data-status='approved']", "อนุมัติแล้ว"
    assert_select "#order_created_at", I18n.l(order.created_at)
    assert_select "#order_decided_at", I18n.l(order.decided_at)
    assert_select "#order_decided_by", users(:admin).name
    assert_select "#order_fulfilled_at", 0
  end

  test "show a pending order has no decision timestamps" do
    get order_path(orders(:pending_one))

    assert_select "#order_status .order-status", "รออนุมัติ"
    assert_select "#order_decided_at", 0
  end

  test "show a rejected order with its reason" do
    sign_in_as users(:two)

    get order_path(orders(:rejected_two))

    assert_select "#order_status .order-status", "ไม่อนุมัติ"
    assert_select "#order_timeline dt", /วันที่ไม่อนุมัติ/
    assert_select "#admin_note", /เบิกเกินความจำเป็น/
  end

  test "index shows status badges" do
    get orders_path

    assert_select "##{dom_id(orders(:approved_one))} .order-status", "อนุมัติแล้ว"
  end
end
