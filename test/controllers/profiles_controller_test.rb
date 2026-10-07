require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "requires sign in" do
    sign_out

    get profile_path
    assert_redirected_to new_session_path

    get edit_profile_path
    assert_redirected_to new_session_path

    patch profile_path, params: { user: { name: "ชื่อใหม่" } }
    assert_redirected_to new_session_path
    assert_equal "สมชาย ใจดี", @user.reload.name
  end

  test "show displays the current user's name, email, and role" do
    get profile_path

    assert_response :success
    assert_select "#profile_name", @user.name
    assert_select "#profile_email", @user.email_address
    assert_select "#profile_role", "ผู้ใช้"
  end

  test "show displays the admin role for admins" do
    sign_in_as users(:admin)

    get profile_path

    assert_select "#profile_name", users(:admin).name
    assert_select "#profile_role", "ผู้ดูแลระบบ"
  end

  test "show ignores an id in params and displays the current user" do
    get profile_path(id: users(:two).id)

    assert_select "#profile_email", @user.email_address
    assert_select "#profile_email", { text: users(:two).email_address, count: 0 }
  end

  test "edit renders the form without email, role, or active fields" do
    get edit_profile_path

    assert_response :success
    assert_select "form[action=?]", profile_path
    assert_select "input[name=?][value=?]", "user[name]", @user.name
    assert_select "input[name=?]", "user[current_password]"
    assert_select "input[name=?]", "user[password]"
    assert_select "input[name=?]", "user[password_confirmation]"
    assert_select "[name=?]", "user[email_address]", 0
    assert_select "[name=?]", "user[role]", 0
    assert_select "[name=?]", "user[active]", 0
  end

  test "update changes the name" do
    patch profile_path, params: { user: { name: "สมชาย ใหม่" } }

    assert_redirected_to profile_path
    assert_equal "สมชาย ใหม่", @user.reload.name
  end

  test "update rejects a blank name" do
    patch profile_path, params: { user: { name: " " } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
    assert_equal "สมชาย ใจดี", @user.reload.name
  end

  test "update ignores email, role, and active" do
    patch profile_path, params: { user: { name: "สมชาย", email_address: "hacker@example.com", role: "admin", active: "false" } }

    assert_redirected_to profile_path
    @user.reload
    assert_equal "one@example.com", @user.email_address
    assert @user.user?
    assert @user.active?
  end

  test "update only affects the current user even when another id is given" do
    patch profile_path(id: users(:two).id), params: { id: users(:two).id, user: { name: "เปลี่ยนชื่อ" } }

    assert_equal "เปลี่ยนชื่อ", @user.reload.name
    assert_equal "สมหญิง รักงาน", users(:two).reload.name
  end

  test "update changes the password with the correct current password" do
    patch profile_path, params: { user: { name: @user.name, current_password: "password", password: "new-secret-123", password_confirmation: "new-secret-123" } }

    assert_redirected_to profile_path
    assert @user.reload.authenticate("new-secret-123")
  end

  test "changing the password signs out other sessions but keeps the current one" do
    other_session = @user.sessions.create!

    patch profile_path, params: { user: { name: @user.name, current_password: "password", password: "new-secret-123", password_confirmation: "new-secret-123" } }

    assert_not Session.exists?(other_session.id)
    get profile_path
    assert_response :success
  end

  test "update rejects a wrong current password" do
    patch profile_path, params: { user: { name: "ชื่อใหม่", current_password: "wrong-password", password: "new-secret-123", password_confirmation: "new-secret-123" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /รหัสผ่านปัจจุบันไม่ถูกต้อง/
    @user.reload
    assert @user.authenticate("password")
    assert_equal "สมชาย ใจดี", @user.name
  end

  test "update rejects a missing current password" do
    patch profile_path, params: { user: { name: @user.name, password: "new-secret-123", password_confirmation: "new-secret-123" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /รหัสผ่านปัจจุบันไม่ถูกต้อง/
    assert @user.reload.authenticate("password")
  end

  test "update rejects a password shorter than 8 characters" do
    patch profile_path, params: { user: { name: @user.name, current_password: "password", password: "short12", password_confirmation: "short12" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /อย่างน้อย 8 ตัวอักษร/
    assert @user.reload.authenticate("password")
  end

  test "update accepts a password of exactly 8 characters" do
    patch profile_path, params: { user: { name: @user.name, current_password: "password", password: "eight888", password_confirmation: "eight888" } }

    assert_redirected_to profile_path
    assert @user.reload.authenticate("eight888")
  end

  test "update rejects a mismatched password confirmation" do
    patch profile_path, params: { user: { name: @user.name, current_password: "password", password: "new-secret-123", password_confirmation: "different-123" } }

    assert_response :unprocessable_entity
    assert_select "#error_explanation", /ยืนยันรหัสผ่าน/
    assert @user.reload.authenticate("password")
  end

  test "update keeps the password when password fields are blank" do
    patch profile_path, params: { user: { name: "ชื่อใหม่", current_password: "", password: "", password_confirmation: "" } }

    assert_redirected_to profile_path
    @user.reload
    assert_equal "ชื่อใหม่", @user.name
    assert @user.authenticate("password")
  end

  test "update without user params is a bad request" do
    patch profile_path, params: {}

    assert_response :bad_request
  end
end
