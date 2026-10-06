require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "index lists users" do
    get admin_users_path

    assert_response :success
    assert_select "#users tbody tr", User.count
    assert_select "##{dom_id(users(:inactive))}", /ระงับ/
  end

  test "index hides the deactivate button for the current admin" do
    get admin_users_path

    assert_select "##{dom_id(users(:admin))} form", 0
    assert_select "##{dom_id(users(:one))} form"
  end

  test "new" do
    get new_admin_user_path

    assert_response :success
  end

  test "create a user" do
    assert_difference -> { User.count }, 1 do
      post admin_users_path, params: { user: { name: "ผู้ใช้ใหม่", email_address: "New@Example.com", role: "user", password: "secret123", password_confirmation: "secret123" } }
    end

    assert_redirected_to admin_users_path
    user = User.find_by!(email_address: "new@example.com")
    assert user.user?
    assert user.active?
    assert user.authenticate("secret123")
  end

  test "create an admin" do
    post admin_users_path, params: { user: { name: "แอดมินใหม่", email_address: "boss@example.com", role: "admin", password: "secret123", password_confirmation: "secret123" } }

    assert User.find_by!(email_address: "boss@example.com").admin?
  end

  test "create with invalid params re-renders the form" do
    assert_no_difference -> { User.count } do
      post admin_users_path, params: { user: { name: "", email_address: users(:one).email_address, role: "user", password: "secret123", password_confirmation: "different" } }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation li", minimum: 3
  end

  test "edit" do
    get edit_admin_user_path(users(:one))

    assert_response :success
  end

  test "update changes the role" do
    patch admin_user_path(users(:one)), params: { user: { role: "admin" } }

    assert_redirected_to admin_users_path
    assert users(:one).reload.admin?
  end

  test "update with a blank password keeps the current password" do
    patch admin_user_path(users(:one)), params: { user: { name: "ชื่อใหม่", password: "", password_confirmation: "" } }

    assert_redirected_to admin_users_path
    assert_equal "ชื่อใหม่", users(:one).reload.name
    assert users(:one).authenticate("password")
  end

  test "update with invalid params re-renders the form" do
    patch admin_user_path(users(:one)), params: { user: { role: "superuser" } }

    assert_response :unprocessable_entity
    assert users(:one).reload.user?
  end

  test "update ignores the active attribute" do
    patch admin_user_path(users(:one)), params: { user: { active: "0" } }

    assert users(:one).reload.active?
  end

  test "unknown user returns not found" do
    get edit_admin_user_path(id: 0)

    assert_response :not_found
  end

  test "users cannot manage users" do
    sign_in_as users(:one)

    get admin_users_path
    assert_redirected_to root_path
    assert_equal "ไม่มีสิทธิ์เข้าถึง", flash[:alert]

    get new_admin_user_path
    assert_redirected_to root_path

    get edit_admin_user_path(users(:two))
    assert_redirected_to root_path

    assert_no_difference -> { User.count } do
      post admin_users_path, params: { user: { name: "x", email_address: "x@example.com", role: "admin", password: "secret123", password_confirmation: "secret123" } }
    end
    assert_redirected_to root_path

    patch admin_user_path(users(:one)), params: { user: { role: "admin" } }
    assert_redirected_to root_path
    assert users(:one).reload.user?
  end

  test "signed out visitors are asked to sign in" do
    sign_out

    get admin_users_path

    assert_redirected_to new_session_path
  end
end
