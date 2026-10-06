module OrdersHelper
  STATUS_BADGE_CLASSES = {
    "pending" => "bg-amber-100 text-amber-800",
    "approved" => "bg-green-100 text-green-800",
    "rejected" => "bg-red-100 text-red-800",
    "cancelled" => "bg-gray-200 text-gray-700",
    "fulfilled" => "bg-blue-100 text-blue-800"
  }.freeze

  def order_status_badge(order)
    tag.span order.status_name,
      class: [ "order-status rounded-full px-2.5 py-0.5 text-sm font-medium whitespace-nowrap", STATUS_BADGE_CLASSES.fetch(order.status) ],
      data: { status: order.status }
  end
end
