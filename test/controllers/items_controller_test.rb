require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "index lists active items only" do
    get items_path

    assert_response :success
    assert_select "#items tbody tr", Item.active.count
    assert_select "##{dom_id(items(:paper))}"
    assert_select "##{dom_id(items(:retired))}", 0
  end

  test "index is read-only for users" do
    get items_path

    assert_select "a[href=?]", new_admin_item_path, 0
    assert_select "a[href=?]", edit_admin_item_path(items(:paper)), 0
  end

  test "show an active item" do
    get item_path(items(:paper))

    assert_response :success
    assert_select "h1", items(:paper).name
    assert_select "#quantity", /50/
    assert_select "#admin_actions", 0
  end

  test "users get not found for inactive items" do
    get item_path(items(:retired))

    assert_response :not_found
  end

  test "admins can view inactive items and see admin actions" do
    sign_in_as users(:admin)

    get item_path(items(:retired))

    assert_response :success
    assert_select "#admin_actions"
  end

  test "requires sign in" do
    sign_out

    get items_path
    assert_redirected_to new_session_path

    get item_path(items(:paper))
    assert_redirected_to new_session_path
  end
end
