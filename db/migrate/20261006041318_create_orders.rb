class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.text :purpose, null: false
      t.text :admin_note
      t.references :decided_by, foreign_key: { to_table: :users }
      t.datetime :decided_at
      t.datetime :fulfilled_at

      t.timestamps
    end
    add_index :orders, %i[status created_at]
    add_check_constraint :orders, "status IN ('pending', 'approved', 'rejected', 'cancelled', 'fulfilled')", name: "orders_status_check"
  end
end
