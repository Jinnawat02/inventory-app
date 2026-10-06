require "test_helper"

class OrderNotificationsTest < ActionDispatch::IntegrationTest
  test "creating an order emails the admins" do
    sign_in_as users(:one)

    post orders_path, params: { order: { purpose: "จัดอบรม", order_items_attributes: { "0" => { item_id: items(:paper).id, quantity: "2" } } } }

    assert_enqueued_email_with OrderMailer, :new_request, args: [ Order.last ]
  end

  test "an invalid order sends nothing" do
    sign_in_as users(:one)

    assert_no_enqueued_emails do
      post orders_path, params: { order: { purpose: "", order_items_attributes: { "0" => { item_id: items(:paper).id, quantity: "2" } } } }
    end
  end

  test "editing a pending order sends nothing" do
    sign_in_as users(:one)

    assert_no_enqueued_emails do
      patch order_path(orders(:pending_one)), params: { order: { purpose: "แก้ไขแล้ว" } }
    end
  end

  test "approving emails the owner" do
    sign_in_as users(:admin)

    post admin_order_approval_path(orders(:pending_one))

    assert_enqueued_email_with OrderMailer, :status_changed, args: [ orders(:pending_one), "approved" ]
  end

  test "rejecting emails the owner" do
    sign_in_as users(:admin)

    post admin_order_rejection_path(orders(:pending_two)), params: { order: { admin_note: "งบหมด" } }

    assert_enqueued_email_with OrderMailer, :status_changed, args: [ orders(:pending_two), "rejected" ]
  end

  test "fulfilling emails the owner" do
    sign_in_as users(:admin)

    post admin_order_fulfillment_path(orders(:approved_one))

    assert_enqueued_email_with OrderMailer, :status_changed, args: [ orders(:approved_one), "fulfilled" ]
  end

  test "a user cancelling their order sends nothing" do
    sign_in_as users(:one)

    assert_no_enqueued_emails do
      post order_cancellation_path(orders(:pending_one))
    end

    assert orders(:pending_one).reload.cancelled?
  end

  test "an approval refused for insufficient stock sends nothing" do
    order_items(:pending_two_toner).update!(quantity: 99)
    sign_in_as users(:admin)

    assert_no_enqueued_emails do
      post admin_order_approval_path(orders(:pending_two))
    end

    assert orders(:pending_two).reload.pending?
  end

  test "a rejection without a reason sends nothing" do
    sign_in_as users(:admin)

    assert_no_enqueued_emails do
      post admin_order_rejection_path(orders(:pending_two)), params: { order: { admin_note: "" } }
    end
  end

  test "an invalid transition sends nothing" do
    sign_in_as users(:admin)

    assert_no_enqueued_emails do
      post admin_order_fulfillment_path(orders(:pending_one))
      post admin_order_approval_path(orders(:rejected_two))
    end
  end
end
