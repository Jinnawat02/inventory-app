class Admin::ItemsController < Admin::BaseController
  include ItemFiltering

  before_action :set_item, only: %i[edit update destroy]

  def index
    @items = Item.ordered.filter_by(**item_filters)
  end

  def new
    @item = Item.new
  end

  def create
    @item = Item.new(item_params)

    if @item.save
      redirect_to admin_items_path, notice: "เพิ่มพัสดุเรียบร้อยแล้ว"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @item.update(item_params.except(:quantity))
      redirect_to admin_items_path, notice: "บันทึกข้อมูลพัสดุเรียบร้อยแล้ว"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @item.destroy
      redirect_to admin_items_path, notice: "ลบพัสดุเรียบร้อยแล้ว", status: :see_other
    else
      redirect_to admin_items_path, alert: @item.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_item
      @item = Item.find(params[:id])
    end

    def item_params
      params.expect(item: %i[name sku description unit quantity low_stock_threshold active])
    end
end
