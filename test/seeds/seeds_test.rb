require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  SEED_ENV = {
    "SEED_ADMIN_EMAIL" => "seed-admin@example.com",
    "SEED_ADMIN_PASSWORD" => "fake-admin-password",
    "SEED_USER_PASSWORD" => "fake-user-password"
  }.freeze

  def with_env(values)
    previous = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end

  test "creates one admin and two users from environment variables" do
    with_env(SEED_ENV) do
      assert_difference -> { User.count }, 3 do
        Rails.application.load_seed
      end
    end

    admin = User.find_by!(email_address: "seed-admin@example.com")
    assert admin.admin?
    assert admin.authenticate("fake-admin-password")

    users = User.where(email_address: %w[somchai@example.com somying@example.com])
    assert_equal 2, users.count
    assert users.all?(&:user?)
    assert users.all? { |user| user.authenticate("fake-user-password") }
  end

  test "creates 10 sample items" do
    Item.delete_all

    with_env(SEED_ENV) do
      assert_difference -> { Item.count }, 10 do
        Rails.application.load_seed
      end
    end

    assert Item.all.all?(&:valid?)
    assert Item.low_stock.exists?
  end

  test "is idempotent" do
    with_env(SEED_ENV) do
      Rails.application.load_seed

      assert_no_difference [ -> { User.count }, -> { Item.count } ] do
        Rails.application.load_seed
      end
    end
  end

  test "requires the seed environment variables" do
    with_env(SEED_ENV.merge("SEED_ADMIN_PASSWORD" => nil)) do
      assert_raises(KeyError) { Rails.application.load_seed }
    end
  end
end
