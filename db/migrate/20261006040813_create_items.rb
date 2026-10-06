class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.text :description
      t.string :unit, null: false
      t.integer :quantity, null: false, default: 0
      t.integer :low_stock_threshold, null: false, default: 5
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :items, :sku, unique: true
    add_check_constraint :items, "quantity >= 0", name: "items_quantity_non_negative"
    add_check_constraint :items, "low_stock_threshold >= 0", name: "items_low_stock_threshold_non_negative"
  end
end
