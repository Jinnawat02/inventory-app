require "test_helper"

class Admin::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  def listed_order_ids
    css_select("#orders tbody tr[id^='order_']").map { |row| row["id"].delete_prefix("order_").to_i }
  end

  test "index lists every user's orders with oldest pending first" do
    get admin_orders_path

    assert_response :success
    assert_equal [ orders(:pending_two), orders(:pending_one), orders(:approved_one), orders(:rejected_two) ].map(&:id), listed_order_ids
  end

  test "index filters by status" do
    get admin_orders_path(status: "pending")

    assert_equal [ orders(:pending_two), orders(:pending_one) ].map(&:id), listed_order_ids
    assert_select "#status_filters a[aria-current='page']", "รออนุมัติ"

    get admin_orders_path(status: "rejected")

    assert_equal [ orders(:rejected_two).id ], listed_order_ids
  end

  test "index ignores unknown statuses" do
    get admin_orders_path(status: "lost")

    assert_equal Order.count, listed_order_ids.size
  end

  test "index shows an empty state" do
    get admin_orders_path(status: "fulfilled")

    assert_select "#no_orders"
  end

  test "show any user's order" do
    get admin_order_path(orders(:pending_two))

    assert_response :success
    assert_select "#order_requester", /#{users(:two).name}/
    assert_select "#order_items tbody tr", 1
  end

  test "users cannot see all orders" do
    sign_in_as users(:one)

    get admin_orders_path
    assert_redirected_to root_path
    assert_equal "ไม่มีสิทธิ์เข้าถึง", flash[:alert]

    get admin_order_path(orders(:pending_two))
    assert_redirected_to root_path
  end
end
