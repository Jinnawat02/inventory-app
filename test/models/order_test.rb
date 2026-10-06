require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def build_order(lines: [ { item: items(:paper), quantity: 2 } ], **attributes)
    order = users(:one).orders.new({ purpose: "ใช้งานทั่วไป" }.merge(attributes))
    lines.each { |line| order.order_items.build(line) }
    order
  end

  test "valid with a purpose and one line, defaults to pending" do
    order = build_order
    assert order.valid?
    assert order.pending?
  end

  test "requires a purpose" do
    order = build_order(purpose: "   ")
    assert_not order.valid?
    assert order.errors.added?(:purpose, :blank)
  end

  test "requires at least one line" do
    order = build_order(lines: [])
    assert_not order.valid?
    assert order.errors.added?(:order_items, :too_short)
  end

  test "lines marked for destruction do not count" do
    order = orders(:pending_one)
    order.order_items.each(&:mark_for_destruction)

    assert_not order.valid?
    assert order.errors.added?(:order_items, :too_short)
  end

  test "rejects the same item twice" do
    order = build_order(lines: [ { item: items(:paper), quantity: 1 }, { item: items(:paper), quantity: 2 } ])
    assert_not order.valid?
    assert order.errors.added?(:order_items, :duplicate_item)
  end

  test "creates lines through nested attributes and skips blank rows" do
    order = users(:one).orders.create!(purpose: "จัดบอร์ด", order_items_attributes: [
      { item_id: items(:paper).id, quantity: "2" },
      { item_id: items(:pen).id, quantity: "4" },
      { item_id: "", quantity: "" }
    ])

    assert_equal [ items(:paper), items(:pen) ], order.items.to_a
    assert_equal [ 2, 4 ], order.order_items.map(&:quantity)
  end

  test "rejects unknown statuses" do
    order = build_order(status: "lost")
    assert_not order.valid?
    assert order.errors.of_kind?(:status, :inclusion)
  end

  test "database rejects unknown statuses" do
    assert_raises(ActiveRecord::StatementInvalid) do
      orders(:pending_one).update_column(:status, "lost")
    end
  end

  test "status_name is translated" do
    assert_equal "รออนุมัติ", orders(:pending_one).status_name
    assert_equal "ไม่อนุมัติ", orders(:rejected_two).status_name
  end

  test "cancel! moves a pending order to cancelled" do
    order = orders(:pending_one)
    order.cancel!
    assert order.reload.cancelled?
  end

  test "cancel! refuses orders that are no longer pending" do
    [ orders(:approved_one), orders(:rejected_two) ].each do |order|
      assert_raises(Order::InvalidTransition) { order.cancel! }
      assert_not order.reload.cancelled?
    end
  end

  test "can_transition_to? follows the transition table" do
    pending = orders(:pending_one)
    assert pending.can_transition_to?(:approved)
    assert pending.can_transition_to?(:rejected)
    assert pending.can_transition_to?(:cancelled)
    assert_not pending.can_transition_to?(:fulfilled)

    approved = orders(:approved_one)
    assert approved.can_transition_to?(:fulfilled)
    assert_not approved.can_transition_to?(:cancelled)
    assert_not approved.can_transition_to?(:pending)

    assert_not orders(:rejected_two).can_transition_to?(:approved)
  end

  test "direct status updates outside the table are invalid" do
    order = orders(:rejected_two)
    assert_not order.update(status: "approved")
    assert order.errors.added?(:status, :invalid_transition)

    pending = orders(:pending_one)
    assert_not pending.update(status: "fulfilled")
  end

  test "lines can be changed while pending" do
    order = orders(:pending_one)
    assert order.update(purpose: "แก้ไขวัตถุประสงค์", order_items_attributes: [ { id: order_items(:pending_one_pen).id, _destroy: "1" } ])
    assert_equal [ items(:paper) ], order.reload.items.to_a
  end

  test "lines are locked once the order is decided" do
    order = orders(:approved_one)
    assert_not order.update(order_items_attributes: [ { id: order_items(:approved_one_paper).id, quantity: 99 } ])
    assert order.errors.added?(:order_items, :locked)
    assert_equal 3, order_items(:approved_one_paper).reload.quantity

    assert_not order.update(purpose: "เปลี่ยน")
  end

  test "editable? only while pending" do
    assert orders(:pending_one).editable?
    assert_not orders(:approved_one).editable?
    assert_not Order.new.editable?
  end
end
