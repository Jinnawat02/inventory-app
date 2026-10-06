require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  test "quantity must be a positive integer" do
    [ 0, -1, 1.5, nil ].each do |quantity|
      line = orders(:pending_one).order_items.build(item: items(:toner), quantity: quantity)
      assert_not line.valid?, "#{quantity.inspect} should be invalid"
    end
  end

  test "an item appears at most once per order" do
    line = orders(:pending_one).order_items.build(item: items(:paper), quantity: 1)
    assert_not line.valid?
    assert line.errors.of_kind?(:item_id, :taken)
  end

  test "database enforces one line per item per order" do
    assert_raises(ActiveRecord::RecordNotUnique) do
      OrderItem.insert_all!([ { order_id: orders(:pending_one).id, item_id: items(:paper).id, quantity: 1 } ])
    end
  end

  test "new lines cannot use inactive items" do
    line = orders(:pending_one).order_items.build(item: items(:retired), quantity: 1)
    assert_not line.valid?
    assert line.errors.added?(:item, :inactive)
  end

  test "existing lines stay valid when their item is later deactivated" do
    items(:paper).update!(active: false)
    assert order_items(:pending_one_paper).valid?
  end
end
