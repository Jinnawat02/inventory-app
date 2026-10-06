require "test_helper"

class StockAdjustmentTest < ActiveSupport::TestCase
  setup { @item = items(:paper) }

  test "adds stock" do
    assert StockAdjustment.new(item: @item, change: 25).save
    assert_equal 75, @item.reload.quantity
  end

  test "removes stock" do
    assert StockAdjustment.new(item: @item, change: -50).save
    assert_equal 0, @item.reload.quantity
  end

  test "refuses to take stock below zero" do
    adjustment = StockAdjustment.new(item: @item, change: -51)

    assert_not adjustment.save
    assert adjustment.errors.added?(:change, :insufficient_stock)
    assert_equal 50, @item.reload.quantity
  end

  test "requires a non-zero integer change" do
    [ nil, 0, "abc", "1.5" ].each do |change|
      assert_not StockAdjustment.new(item: @item, change: change).valid?, "#{change.inspect} should be invalid"
    end
  end
end
