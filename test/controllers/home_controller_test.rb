require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get root" do
    sign_in_as users(:one)

    get root_url

    assert_response :success
    assert_select "h1", "Inventory App"
    assert_select "#current_user", users(:one).name
  end

  test "requires sign in" do
    get root_url

    assert_redirected_to new_session_path
  end
end
