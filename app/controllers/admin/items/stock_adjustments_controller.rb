class Admin::Items::StockAdjustmentsController < Admin::BaseController
  before_action :set_item

  def new
    @stock_adjustment = StockAdjustment.new(item: @item)
  end

  def create
    @stock_adjustment = StockAdjustment.new(item: @item, **stock_adjustment_params)

    if @stock_adjustment.save
      redirect_to admin_items_path, notice: "ปรับสต็อก #{@item.name} เป็น #{@item.quantity} #{@item.unit} แล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_item
      @item = Item.find(params[:item_id])
    end

    def stock_adjustment_params
      params.expect(stock_adjustment: [ :change ]).to_h.symbolize_keys
    end
end
