require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "show summarizes items and active users" do
    get dashboard_path

    assert_response :success
    assert_select "#active_items_count", /3/
    assert_select "#low_stock_items_count", /1/
    assert_select "#inactive_items_count", /1/
    assert_select "#active_admin_count", /ผู้ดูแลระบบ\s*1/
    assert_select "#active_user_count", /ผู้ใช้\s*2/
  end

  test "show lists active low stock items linking to the item page" do
    get dashboard_path

    assert_select "#low_stock_items tbody tr", 1
    assert_select "##{dom_id(items(:toner))}" do
      assert_select "a[href=?]", item_path(items(:toner)), items(:toner).name
      assert_select "td", items(:toner).sku
      assert_select "td", items(:toner).unit
    end
    assert_select "##{dom_id(items(:retired))}", 0
    assert_select "##{dom_id(items(:paper))}", 0
  end

  test "show lists at most ten low stock items with the lowest quantity first" do
    12.times do |index|
      Item.create!(name: "พัสดุ #{index}", sku: "LOW-#{index}", unit: "ชิ้น", quantity: index + 3, low_stock_threshold: 100)
    end

    get dashboard_path

    assert_select "#low_stock_items tbody tr", 10
    assert_select "#low_stock_items tbody tr:first-child", /#{items(:toner).name}/
    assert_select "#low_stock_items tbody tr", text: /LOW-10/, count: 0
    assert_select "#low_stock_items_count", /13/
  end

  test "show an empty state when no active item is low on stock" do
    items(:toner).update!(quantity: 100)

    get dashboard_path

    assert_select "#no_low_stock_items", "ไม่มีพัสดุสต็อกต่ำ"
  end

  test "users are redirected" do
    sign_in_as users(:one)

    get dashboard_path

    assert_redirected_to root_path
    assert_equal "ไม่มีสิทธิ์เข้าถึง", flash[:alert]
  end

  test "requires sign in" do
    sign_out

    get dashboard_path

    assert_redirected_to new_session_path
  end
end
