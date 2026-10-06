require "test_helper"

class Admin::ItemsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  def valid_params
    { item: { name: "แฟ้มเอกสาร", sku: "file-02", description: "แฟ้มสันกว้าง", unit: "เล่ม", quantity: 30, low_stock_threshold: 5, active: "1" } }
  end

  test "index lists all items including inactive ones" do
    get admin_items_path

    assert_response :success
    assert_select "#items tbody tr", Item.count
    assert_select "##{dom_id(items(:retired))}", /ปิดใช้งาน/
  end

  test "index searches and filters low stock including inactive items" do
    get admin_items_path, params: { q: "floppy" }
    assert_select "#items tbody tr", 1
    assert_select "##{dom_id(items(:retired))}"

    get admin_items_path, params: { low_stock: "1" }
    assert_select "##{dom_id(items(:toner))} .low-stock-badge"
    assert_select "##{dom_id(items(:retired))}"
    assert_select "##{dom_id(items(:paper))}", 0
  end

  test "new" do
    get new_admin_item_path

    assert_response :success
  end

  test "create" do
    assert_difference -> { Item.count }, 1 do
      post admin_items_path, params: valid_params
    end

    assert_redirected_to admin_items_path
    item = Item.find_by!(sku: "FILE-02")
    assert_equal 30, item.quantity
  end

  test "create with invalid params re-renders the form" do
    assert_no_difference -> { Item.count } do
      post admin_items_path, params: { item: { name: "", sku: "PAPER-A4", unit: "", quantity: -1 } }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation li", minimum: 4
  end

  test "edit" do
    get edit_admin_item_path(items(:paper))

    assert_response :success
    assert_select "input[name='item[quantity]']", 0
  end

  test "update" do
    patch admin_item_path(items(:paper)), params: { item: { name: "กระดาษ A4 70 แกรม", low_stock_threshold: 15, active: "0" } }

    assert_redirected_to admin_items_path
    items(:paper).reload.then do |item|
      assert_equal "กระดาษ A4 70 แกรม", item.name
      assert_equal 15, item.low_stock_threshold
      assert_not item.active?
    end
  end

  test "update does not change quantity directly" do
    patch admin_item_path(items(:paper)), params: { item: { quantity: 999 } }

    assert_equal 50, items(:paper).reload.quantity
  end

  test "update with invalid params re-renders the form" do
    patch admin_item_path(items(:paper)), params: { item: { sku: "bad sku" } }

    assert_response :unprocessable_entity
    assert_equal "PAPER-A4", items(:paper).reload.sku
  end

  test "destroy" do
    assert_difference -> { Item.count }, -1 do
      delete admin_item_path(items(:pen))
    end

    assert_redirected_to admin_items_path
  end

  test "users cannot manage items" do
    sign_in_as users(:one)

    get admin_items_path
    assert_redirected_to root_path
    assert_equal "ไม่มีสิทธิ์เข้าถึง", flash[:alert]

    get new_admin_item_path
    assert_redirected_to root_path

    get edit_admin_item_path(items(:paper))
    assert_redirected_to root_path

    assert_no_difference -> { Item.count } do
      post admin_items_path, params: valid_params
    end
    assert_redirected_to root_path

    patch admin_item_path(items(:paper)), params: { item: { name: "แก้ไข" } }
    assert_redirected_to root_path
    assert_equal "กระดาษ A4", items(:paper).reload.name

    assert_no_difference -> { Item.count } do
      delete admin_item_path(items(:paper))
    end
    assert_redirected_to root_path
  end
end
