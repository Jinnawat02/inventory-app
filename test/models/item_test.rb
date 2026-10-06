require "test_helper"

class ItemTest < ActiveSupport::TestCase
  def build_item(**attributes)
    Item.new({ name: "แฟ้ม", sku: "FILE-01", unit: "เล่ม" }.merge(attributes))
  end

  test "valid with required attributes and defaults" do
    item = build_item
    assert item.valid?
    assert_equal 0, item.quantity
    assert_equal 5, item.low_stock_threshold
    assert item.active?
  end

  test "requires name, sku and unit" do
    item = Item.new
    assert_not item.valid?
    assert item.errors.added?(:name, :blank)
    assert item.errors.added?(:sku, :blank)
    assert item.errors.added?(:unit, :blank)
  end

  test "normalizes sku to stripped uppercase" do
    assert_equal "FILE-01", build_item(sku: "  file-01 ").sku
  end

  test "rejects sku characters outside A-Z, 0-9 and dash" do
    [ "FILE 01", "FILE_01", "แฟ้ม" ].each do |sku|
      assert_not build_item(sku: sku).valid?, "#{sku} should be invalid"
    end
  end

  test "requires a unique sku regardless of case" do
    item = build_item(sku: "paper-a4")
    assert_not item.valid?
    assert item.errors.added?(:sku, :taken, value: "PAPER-A4")
  end

  test "quantity and threshold must be non-negative integers" do
    assert_not build_item(quantity: -1).valid?
    assert_not build_item(low_stock_threshold: -1).valid?
    assert_not build_item(quantity: 1.5).valid?
  end

  test "database rejects negative quantity" do
    assert_raises(ActiveRecord::StatementInvalid) do
      items(:paper).update_column(:quantity, -1)
    end
  end

  test "low_stock? when quantity is at or below the threshold" do
    assert items(:toner).low_stock?
    assert build_item(quantity: 5, low_stock_threshold: 5).low_stock?
    assert_not items(:paper).low_stock?
  end

  test "active scope excludes inactive items" do
    assert_includes Item.active, items(:paper)
    assert_not_includes Item.active, items(:retired)
  end
end
