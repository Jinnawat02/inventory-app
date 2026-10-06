require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "create with valid credentials for an inactive user" do
    inactive = users(:inactive)

    post session_path, params: { email_address: inactive.email_address, password: "password" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
    follow_redirect!
    assert_select "#alert", "บัญชีนี้ถูกระงับการใช้งาน"
  end

  test "existing session stops working once the user is deactivated" do
    sign_in_as @user
    get root_path
    assert_response :success

    @user.update!(active: false)
    get root_path

    assert_redirected_to new_session_path
  end

  test "create redirects back to the originally requested page" do
    get root_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: @user.email_address, password: "password" }

    assert_redirected_to root_url
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
