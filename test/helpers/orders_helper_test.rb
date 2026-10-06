require "test_helper"

class OrdersHelperTest < ActionView::TestCase
  test "order_status_badge shows the Thai status with a status-specific style" do
    badge = order_status_badge(orders(:pending_one))

    assert_includes badge, "รออนุมัติ"
    assert_includes badge, "bg-amber-100"
    assert_includes badge, 'data-status="pending"'
  end

  test "every status has a badge style" do
    Order.statuses.each_key do |status|
      assert OrdersHelper::STATUS_BADGE_CLASSES.key?(status), "#{status} has no badge style"
    end
  end
end
