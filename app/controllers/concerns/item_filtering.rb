module ItemFiltering
  extend ActiveSupport::Concern

  included do
    helper_method :item_filters
  end

  private
    def item_filters
      { query: params[:q].presence, low_stock: params[:low_stock] == "1" }
    end
end
