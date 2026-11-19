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

ActiveRecord::Schema[8.1].define(version: 2026_11_18_220000) do
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
    t.integer "status"
    t.bigint "company_id", null: false
    t.bigint "account_id", null: false
    t.bigint "category_id", null: false
    t.bigint "subcategory_id", null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "related_account_id"
    t.index ["account_id"], name: "index_movements_on_account_id"
    t.index ["category_id"], name: "index_movements_on_category_id"
    t.index ["company_id"], name: "index_movements_on_company_id"
    t.index ["created_by_id"], name: "index_movements_on_created_by_id"
    t.index ["related_account_id"], name: "index_movements_on_related_account_id"
    t.index ["subcategory_id"], name: "index_movements_on_subcategory_id"
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

  create_table "subcategories", force: :cascade do |t|
    t.string "name"
    t.bigint "company_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_subcategories_on_category_id"
    t.index ["company_id"], name: "index_subcategories_on_company_id"
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
  add_foreign_key "roles", "companies"
  add_foreign_key "subcategories", "categories"
  add_foreign_key "subcategories", "companies"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "roles"
end
