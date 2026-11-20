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

ActiveRecord::Schema[8.1].define(version: 2026_11_20_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.integer "account_type"
    t.decimal "current_balance"
    t.decimal "initial_balance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id", null: false
    t.index ["company_id"], name: "index_accounts_on_company_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.boolean "is_income", default: false, null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_categories_on_company_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "cnpj"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "movements", force: :cascade do |t|
    t.integer "mv_type"
    t.decimal "amount"
    t.datetime "occurred_at"
    t.text "description"
    t.integer "status", default: 1, null: false
    t.bigint "company_id", null: false
    t.bigint "account_id", null: false
    t.bigint "category_id"
    t.bigint "subcategory_id"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "related_account_id"
    t.datetime "paid_at"
    t.index ["account_id"], name: "index_movements_on_account_id"
    t.index ["category_id"], name: "index_movements_on_category_id"
    t.index ["company_id"], name: "index_movements_on_company_id"
    t.index ["created_by_id"], name: "index_movements_on_created_by_id"
    t.index ["related_account_id"], name: "index_movements_on_related_account_id"
    t.index ["status"], name: "index_movements_on_status"
    t.index ["subcategory_id"], name: "index_movements_on_subcategory_id"
  end

  create_table "product_suppliers", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "supplier_id", null: false
    t.decimal "last_price", precision: 12, scale: 4
    t.string "supplier_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "supplier_id"], name: "index_product_suppliers_on_product_id_and_supplier_id", unique: true
    t.index ["product_id"], name: "index_product_suppliers_on_product_id"
    t.index ["supplier_id"], name: "index_product_suppliers_on_supplier_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "subcategory_id"
    t.string "name", null: false
    t.string "code"
    t.string "unit", default: "un", null: false
    t.decimal "quantity", precision: 12, scale: 3, default: "0.0", null: false
    t.decimal "min_quantity", precision: 12, scale: 3
    t.decimal "average_cost", precision: 12, scale: 4, default: "0.0", null: false
    t.decimal "sale_price", precision: 12, scale: 2
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_products_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_products_on_company_id"
    t.index ["subcategory_id"], name: "index_products_on_subcategory_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "key"
    t.boolean "system", default: false, null: false
    t.string "permissions", default: [], null: false, array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.index ["company_id", "key"], name: "index_roles_on_company_id_and_key", unique: true
    t.index ["company_id", "name"], name: "index_roles_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_roles_on_company_id"
    t.index ["key"], name: "index_roles_on_global_key", unique: true, where: "(company_id IS NULL)"
    t.index ["name"], name: "index_roles_on_global_name", unique: true, where: "(company_id IS NULL)"
  end

  create_table "stock_count_items", force: :cascade do |t|
    t.bigint "stock_count_id", null: false
    t.bigint "product_id", null: false
    t.decimal "expected_quantity", precision: 12, scale: 3, null: false
    t.decimal "counted_quantity", precision: 12, scale: 3
    t.decimal "difference", precision: 12, scale: 3
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_stock_count_items_on_product_id"
    t.index ["stock_count_id", "product_id"], name: "index_stock_count_items_on_stock_count_id_and_product_id", unique: true
    t.index ["stock_count_id"], name: "index_stock_count_items_on_stock_count_id"
  end

  create_table "stock_counts", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "created_by_id"
    t.bigint "finished_by_id"
    t.integer "status", default: 0, null: false
    t.datetime "finished_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "closing_value", precision: 14, scale: 2
    t.index ["company_id"], name: "index_stock_counts_on_company_id"
    t.index ["company_id"], name: "index_stock_counts_one_open_per_company", unique: true, where: "(status = 0)"
    t.index ["created_by_id"], name: "index_stock_counts_on_created_by_id"
    t.index ["finished_by_id"], name: "index_stock_counts_on_finished_by_id"
  end

  create_table "stock_entries", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "supplier_id", null: false
    t.bigint "account_id", null: false
    t.bigint "subcategory_id", null: false
    t.bigint "movement_id"
    t.bigint "created_by_id"
    t.date "received_on", null: false
    t.integer "payment_method", null: false
    t.date "due_on"
    t.string "invoice_number"
    t.decimal "total", precision: 12, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_stock_entries_on_account_id"
    t.index ["company_id"], name: "index_stock_entries_on_company_id"
    t.index ["created_by_id"], name: "index_stock_entries_on_created_by_id"
    t.index ["movement_id"], name: "index_stock_entries_on_movement_id"
    t.index ["subcategory_id"], name: "index_stock_entries_on_subcategory_id"
    t.index ["supplier_id"], name: "index_stock_entries_on_supplier_id"
  end

  create_table "stock_entry_items", force: :cascade do |t|
    t.bigint "stock_entry_id", null: false
    t.bigint "product_id", null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.decimal "unit_cost", precision: 12, scale: 4, null: false
    t.decimal "total", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_stock_entry_items_on_product_id"
    t.index ["stock_entry_id"], name: "index_stock_entry_items_on_stock_entry_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "product_id", null: false
    t.bigint "created_by_id"
    t.string "source_type"
    t.bigint "source_id"
    t.integer "kind", null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.decimal "unit_cost", precision: 12, scale: 4
    t.string "reason"
    t.text "notes"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_stock_movements_on_company_id"
    t.index ["created_by_id"], name: "index_stock_movements_on_created_by_id"
    t.index ["product_id", "occurred_at"], name: "index_stock_movements_on_product_id_and_occurred_at"
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["source_type", "source_id"], name: "index_stock_movements_on_source"
  end

  create_table "subcategories", force: :cascade do |t|
    t.string "name"
    t.bigint "company_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subcategories_on_category_id"
    t.index ["company_id"], name: "index_subcategories_on_company_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.string "cnpj"
    t.string "contact_name"
    t.string "phone"
    t.string "email"
    t.text "notes"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_suppliers_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_suppliers_on_company_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.bigint "company_id"
    t.bigint "role_id"
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "accounts", "companies"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "categories", "companies"
  add_foreign_key "movements", "accounts"
  add_foreign_key "movements", "accounts", column: "related_account_id", on_delete: :nullify
  add_foreign_key "movements", "categories"
  add_foreign_key "movements", "companies"
  add_foreign_key "movements", "subcategories"
  add_foreign_key "movements", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "product_suppliers", "products"
  add_foreign_key "product_suppliers", "suppliers"
  add_foreign_key "products", "companies"
  add_foreign_key "products", "subcategories", on_delete: :nullify
  add_foreign_key "roles", "companies"
  add_foreign_key "stock_count_items", "products"
  add_foreign_key "stock_count_items", "stock_counts"
  add_foreign_key "stock_counts", "companies"
  add_foreign_key "stock_counts", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "stock_counts", "users", column: "finished_by_id", on_delete: :nullify
  add_foreign_key "stock_entries", "accounts"
  add_foreign_key "stock_entries", "companies"
  add_foreign_key "stock_entries", "movements", on_delete: :nullify
  add_foreign_key "stock_entries", "subcategories"
  add_foreign_key "stock_entries", "suppliers"
  add_foreign_key "stock_entries", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "stock_entry_items", "products"
  add_foreign_key "stock_entry_items", "stock_entries"
  add_foreign_key "stock_movements", "companies"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "subcategories", "categories"
  add_foreign_key "subcategories", "companies"
  add_foreign_key "suppliers", "companies"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "roles"
end
