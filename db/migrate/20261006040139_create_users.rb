class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "user"
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_check_constraint :users, "role IN ('user', 'admin')", name: "users_role_check"
  end
end
