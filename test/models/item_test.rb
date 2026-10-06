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

  test "low_stock scope returns items at or below their threshold" do
    assert_equal [ items(:retired), items(:toner) ].sort_by(&:id), Item.low_stock.sort_by(&:id)
  end

  test "search matches name" do
    assert_equal [ items(:paper) ], Item.search("กระดาษ").to_a
  end

  test "search matches sku case-insensitively" do
    assert_equal [ items(:pen) ], Item.search("pen-b").to_a
  end

  test "search treats LIKE wildcards literally" do
    assert_empty Item.search("%")
    assert_empty Item.search("_")
  end

  test "filter_by combines search and low stock" do
    assert_equal [ items(:toner) ], Item.filter_by(query: "toner", low_stock: true).to_a
    assert_empty Item.filter_by(query: "paper", low_stock: true)
    assert_equal Item.count, Item.filter_by.count
  end

  test "an item that has been requested cannot be deleted" do
    item = items(:paper)

    assert_not item.destroy
    assert_match "ไม่สามารถลบได้", item.errors[:base].to_sentence
    assert Item.exists?(item.id)
  end

  test "an item that was never requested can be deleted" do
    assert items(:retired).destroy
  end
end
