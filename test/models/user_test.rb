require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attributes)
    User.new({ name: "ทดสอบ", email_address: "new@example.com", password: "password" }.merge(attributes))
  end

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "strips name" do
    assert_equal "ทดสอบ", build_user(name: "  ทดสอบ  ").name
  end

  test "valid with required attributes" do
    assert build_user.valid?
  end

  test "requires name" do
    user = build_user(name: "")
    assert_not user.valid?
    assert user.errors.added?(:name, :blank)
  end

  test "requires email_address" do
    user = build_user(email_address: "")
    assert_not user.valid?
    assert user.errors.added?(:email_address, :blank)
  end

  test "requires a well-formed email_address" do
    assert_not build_user(email_address: "not-an-email").valid?
  end

  test "requires a unique email_address regardless of case" do
    user = build_user(email_address: users(:one).email_address.upcase)
    assert_not user.valid?
    assert user.errors.added?(:email_address, :taken, value: users(:one).email_address)
  end

  test "defaults to user role and active" do
    user = User.new
    assert user.user?
    assert user.active?
  end

  test "rejects unknown roles" do
    user = build_user(role: "superuser")
    assert_not user.valid?
    assert user.errors.of_kind?(:role, :inclusion)
  end

  test "admin? reflects role" do
    assert users(:admin).admin?
    assert_not users(:one).admin?
  end

  test "database rejects unknown roles" do
    assert_raises(ActiveRecord::StatementInvalid) do
      users(:one).update_column(:role, "superuser")
    end
  end

  test "role_name is translated" do
    assert_equal "ผู้ดูแลระบบ", users(:admin).role_name
    assert_equal "ผู้ใช้", users(:one).role_name
  end

  test "cannot deactivate the current user" do
    Current.session = users(:admin).sessions.create!

    admin = users(:admin)
    assert_not admin.update(active: false)
    assert admin.errors.added?(:active, :cannot_deactivate_self)
    assert admin.reload.active?
  end

  test "can deactivate another user" do
    Current.session = users(:admin).sessions.create!

    assert users(:one).update(active: false)
    assert_not users(:one).reload.active?
  end

  test "deactivating a user ends their sessions" do
    user = users(:one)
    user.sessions.create!

    assert_difference -> { user.sessions.count }, -1 do
      user.update!(active: false)
    end
  end
end
