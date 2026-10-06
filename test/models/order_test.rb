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

  test "admin_queue puts the oldest pending orders first, then the rest newest first" do
    newest_pending = users(:one).orders.create!(purpose: "ล่าสุด", order_items_attributes: [ { item_id: items(:paper).id, quantity: 1 } ])

    assert_equal [ orders(:pending_two), orders(:pending_one), newest_pending, orders(:approved_one), orders(:rejected_two) ], Order.admin_queue.to_a
  end

  test "with_status filters known statuses and ignores unknown ones" do
    assert_equal [ orders(:approved_one) ], Order.with_status("approved").to_a
    assert_equal Order.count, Order.with_status("lost").count
    assert_equal Order.count, Order.with_status(nil).count
  end

  test "approve! records the deciding admin and time" do
    order = orders(:pending_one)

    freeze_time do
      order.approve!(by: users(:admin))

      order.reload
      assert order.approved?
      assert_equal users(:admin), order.decided_by
      assert_equal Time.current, order.decided_at
    end
  end

  test "reject! requires a reason" do
    order = orders(:pending_one)

    assert_raises(ActiveRecord::RecordInvalid) { order.reject!(by: users(:admin), note: "  ") }
    assert order.reload.pending?
  end

  test "reject! stores the reason and deciding admin" do
    order = orders(:pending_one)
    order.reject!(by: users(:admin), note: "งบประมาณไม่พอ")

    order.reload
    assert order.rejected?
    assert_equal "งบประมาณไม่พอ", order.admin_note
    assert_equal users(:admin), order.decided_by
    assert order.decided_at
  end

  test "fulfill! moves an approved order to fulfilled" do
    order = orders(:approved_one)

    freeze_time do
      order.fulfill!
      assert order.reload.fulfilled?
      assert_equal Time.current, order.fulfilled_at
    end
  end

  test "transitions not in the table raise InvalidTransition" do
    assert_raises(Order::InvalidTransition) { orders(:pending_one).fulfill! }
    assert_raises(Order::InvalidTransition) { orders(:approved_one).approve!(by: users(:admin)) }
    assert_raises(Order::InvalidTransition) { orders(:approved_one).reject!(by: users(:admin), note: "x") }
    assert_raises(Order::InvalidTransition) { orders(:rejected_two).approve!(by: users(:admin)) }
    assert_raises(Order::InvalidTransition) { orders(:rejected_two).fulfill! }

    cancelled = orders(:pending_one).tap(&:cancel!)
    assert_raises(Order::InvalidTransition) { cancelled.approve!(by: users(:admin)) }

    fulfilled = orders(:approved_one).tap(&:fulfill!)
    assert_raises(Order::InvalidTransition) { fulfilled.cancel! }
    assert_raises(Order::InvalidTransition) { fulfilled.fulfill! }
  end

  test "transitions re-check the status stored in the database" do
    stale = Order.find(orders(:pending_one).id)
    orders(:pending_one).reject!(by: users(:admin), note: "ซ้ำ")

    assert_raises(Order::InvalidTransition) { stale.approve!(by: users(:admin)) }
    assert Order.find(stale.id).rejected?
  end

  test "approve! deducts stock for every line" do
    assert_difference -> { items(:paper).reload.quantity } => -5, -> { items(:pen).reload.quantity } => -10 do
      orders(:pending_one).approve!(by: users(:admin))
    end
  end

  test "approve! allows taking the exact remaining stock" do
    order_items(:pending_one_paper).update!(quantity: 50)

    orders(:pending_one).approve!(by: users(:admin))

    assert_equal 0, items(:paper).reload.quantity
  end

  test "approve! refuses the whole order when any line is short" do
    order_items(:pending_one_pen).update!(quantity: 121)

    error = assert_raises(Order::InsufficientStock) { orders(:pending_one).approve!(by: users(:admin)) }

    assert_equal [ items(:pen) ], error.shortages.map(&:item)
    assert_equal 121, error.shortages.first.requested
    assert_equal 120, error.shortages.first.available
    assert orders(:pending_one).reload.pending?
    assert_nil orders(:pending_one).decided_by
    assert_equal 50, items(:paper).reload.quantity
    assert_equal 120, items(:pen).reload.quantity
  end

  test "approve! lists every short line" do
    order_items(:pending_one_paper).update!(quantity: 51)
    order_items(:pending_one_pen).update!(quantity: 121)

    error = assert_raises(Order::InsufficientStock) { orders(:pending_one).approve!(by: users(:admin)) }

    assert_equal [ items(:paper), items(:pen) ].sort_by(&:id), error.shortages.map(&:item).sort_by(&:id)
  end

  test "approving two orders for the same item cannot oversell" do
    order_items(:pending_one_paper).update!(quantity: 30)
    second = users(:two).orders.create!(purpose: "แข่งเบิก", order_items_attributes: [ { item_id: items(:paper).id, quantity: 30 } ])

    orders(:pending_one).approve!(by: users(:admin))

    assert_raises(Order::InsufficientStock) { second.approve!(by: users(:admin)) }
    assert_equal 20, items(:paper).reload.quantity
    assert second.reload.pending?
  end

  test "rejecting, cancelling and fulfilling do not touch stock" do
    assert_no_difference -> { Item.sum(:quantity) } do
      orders(:pending_one).reject!(by: users(:admin), note: "ไม่จำเป็น")
      orders(:pending_two).cancel!
      orders(:approved_one).fulfill!
    end
  end
end
