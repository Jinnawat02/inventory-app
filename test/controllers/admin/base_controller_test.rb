require "test_helper"

class Admin::BaseControllerTest < ActionDispatch::IntegrationTest
  class ProbeController < Admin::BaseController
    def index
      render plain: "admin area"
    end
  end

  with_routing do |set|
    set.draw do
      resource :session
      root "home#index"
      get "admin/probe", to: "admin/base_controller_test/probe#index"
    end
  end

  test "admin can access admin pages" do
    sign_in_as users(:admin)

    get "/admin/probe"

    assert_response :success
    assert_equal "admin area", response.body
  end

  test "user is redirected with an access denied message" do
    sign_in_as users(:one)

    get "/admin/probe"

    assert_redirected_to root_path
    assert_equal "ไม่มีสิทธิ์เข้าถึง", flash[:alert]
  end

  test "signed out visitor is asked to sign in" do
    get "/admin/probe"

    assert_redirected_to new_session_path
  end
end
