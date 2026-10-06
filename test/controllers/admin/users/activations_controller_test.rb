require "test_helper"

class Admin::Users::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "deactivate another user" do
    delete admin_user_activation_path(users(:one))

    assert_redirected_to admin_users_path
    assert_not users(:one).reload.active?
  end

  test "deactivated user is signed out" do
    users(:one).sessions.create!

    delete admin_user_activation_path(users(:one))

    assert_equal 0, Session.where(user: users(:one)).count
  end

  test "admin cannot deactivate themselves" do
    delete admin_user_activation_path(users(:admin))

    assert_redirected_to admin_users_path
    assert_equal "สถานะการใช้งานไม่สามารถระงับบัญชีของตนเองได้", flash[:alert]
    assert users(:admin).reload.active?
  end

  test "reactivate a user" do
    post admin_user_activation_path(users(:inactive))

    assert_redirected_to admin_users_path
    assert users(:inactive).reload.active?
  end

  test "users cannot change activation" do
    sign_in_as users(:one)

    delete admin_user_activation_path(users(:two))
    assert_redirected_to root_path
    assert users(:two).reload.active?

    post admin_user_activation_path(users(:inactive))
    assert_redirected_to root_path
    assert_not users(:inactive).reload.active?
  end
end
