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

ActiveRecord::Schema[8.0].define(version: 2025_10_27_205711) do
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
    t.bigint "company_id", null: false
    t.index ["company_id"], name: "index_users_on_company_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounts", "companies"
  add_foreign_key "categories", "companies"
  add_foreign_key "movements", "accounts"
  add_foreign_key "movements", "accounts", column: "related_account_id", on_delete: :nullify
  add_foreign_key "movements", "categories"
  add_foreign_key "movements", "companies"
  add_foreign_key "movements", "subcategories"
  add_foreign_key "movements", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "subcategories", "categories"
  add_foreign_key "subcategories", "companies"
  add_foreign_key "users", "companies"
end
