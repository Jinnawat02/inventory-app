require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get root" do
    sign_in_as users(:one)

    get root_url

    assert_response :success
    assert_select "h1", "Inventory App"
  end
end
