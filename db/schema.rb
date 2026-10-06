# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_06_041320) do
  create_table "items", force: :cascade do |t|
    t.string "name", null: false
    t.string "sku", null: false
    t.text "description"
    t.string "unit", null: false
    t.integer "quantity", default: 0, null: false
    t.integer "low_stock_threshold", default: 5, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_items_on_sku", unique: true
    t.check_constraint "low_stock_threshold >= 0", name: "items_low_stock_threshold_non_negative"
    t.check_constraint "quantity >= 0", name: "items_quantity_non_negative"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "item_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_order_items_on_item_id"
    t.index ["order_id", "item_id"], name: "index_order_items_on_order_id_and_item_id", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "status", default: "pending", null: false
    t.text "purpose", null: false
    t.text "admin_note"
    t.integer "decided_by_id"
    t.datetime "decided_at"
    t.datetime "fulfilled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["decided_by_id"], name: "index_orders_on_decided_by_id"
    t.index ["status", "created_at"], name: "index_orders_on_status_and_created_at"
    t.index ["user_id"], name: "index_orders_on_user_id"
    t.check_constraint "status IN ('pending', 'approved', 'rejected', 'cancelled', 'fulfilled')", name: "orders_status_check"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.check_constraint "role IN ('user', 'admin')", name: "users_role_check"
  end

  add_foreign_key "order_items", "items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "orders", "users", column: "decided_by_id"
  add_foreign_key "sessions", "users"
end
