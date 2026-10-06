require "test_helper"

class UserDeactivationFlowTest < ActionDispatch::IntegrationTest
  test "a user deactivated by an admin can no longer sign in" do
    user = users(:one)

    post session_path, params: { email_address: user.email_address, password: "password" }
    assert_redirected_to root_url
    delete session_path

    post session_path, params: { email_address: users(:admin).email_address, password: "password" }
    delete admin_user_activation_path(user)
    assert_redirected_to admin_users_path
    delete session_path

    post session_path, params: { email_address: user.email_address, password: "password" }
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select "#alert", "บัญชีนี้ถูกระงับการใช้งาน"

    get root_path
    assert_redirected_to new_session_path
  end

  test "a reactivated user can sign in again" do
    sign_in_as users(:admin)
    post admin_user_activation_path(users(:inactive))
    sign_out

    post session_path, params: { email_address: users(:inactive).email_address, password: "password" }

    assert_redirected_to root_url
  end
end
