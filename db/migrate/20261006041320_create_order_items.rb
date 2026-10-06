class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end
    add_index :order_items, %i[order_id item_id], unique: true
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
  end
end
