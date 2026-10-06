require "test_helper"

class Admin::Items::StockAdjustmentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "new shows the current quantity" do
    get new_admin_item_stock_adjustment_path(items(:paper))

    assert_response :success
    assert_select "#current_quantity", "50"
  end

  test "create adds stock" do
    post admin_item_stock_adjustment_path(items(:paper)), params: { stock_adjustment: { change: "10" } }

    assert_redirected_to admin_items_path
    assert_equal 60, items(:paper).reload.quantity
  end

  test "create removes stock" do
    post admin_item_stock_adjustment_path(items(:paper)), params: { stock_adjustment: { change: "-20" } }

    assert_equal 30, items(:paper).reload.quantity
  end

  test "create refuses to go below zero" do
    post admin_item_stock_adjustment_path(items(:paper)), params: { stock_adjustment: { change: "-100" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /ติดลบ/
    assert_equal 50, items(:paper).reload.quantity
  end

  test "users cannot adjust stock" do
    sign_in_as users(:one)

    get new_admin_item_stock_adjustment_path(items(:paper))
    assert_redirected_to root_path

    post admin_item_stock_adjustment_path(items(:paper)), params: { stock_adjustment: { change: "10" } }
    assert_redirected_to root_path
    assert_equal 50, items(:paper).reload.quantity
  end
end
