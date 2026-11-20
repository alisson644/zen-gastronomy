class CreateStockTables < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :cnpj
      t.string :contact_name
      t.string :phone
      t.string :email
      t.text :notes
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :suppliers, [ :company_id, :name ], unique: true

    create_table :products do |t|
      t.references :company, null: false, foreign_key: true
      t.references :subcategory, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.string :code
      t.string :unit, null: false, default: "un"
      t.decimal :quantity, precision: 12, scale: 3, null: false, default: 0
      t.decimal :min_quantity, precision: 12, scale: 3
      t.decimal :average_cost, precision: 12, scale: 4, null: false, default: 0
      t.decimal :sale_price, precision: 12, scale: 2
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :products, [ :company_id, :name ], unique: true

    create_table :product_suppliers do |t|
      t.references :product, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.decimal :last_price, precision: 12, scale: 4
      t.string :supplier_code
      t.timestamps
    end
    add_index :product_suppliers, [ :product_id, :supplier_id ], unique: true

    create_table :stock_entries do |t|
      t.references :company, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :subcategory, null: false, foreign_key: true
      t.references :movement, foreign_key: { on_delete: :nullify }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.date :received_on, null: false
      t.integer :payment_method, null: false
      t.date :due_on
      t.string :invoice_number
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.text :notes
      t.timestamps
    end

    create_table :stock_entry_items do |t|
      t.references :stock_entry, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.decimal :unit_cost, precision: 12, scale: 4, null: false
      t.decimal :total, precision: 12, scale: 2, null: false
      t.timestamps
    end

    create_table :stock_counts do |t|
      t.references :company, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :finished_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :status, null: false, default: 0
      t.datetime :finished_at
      t.text :notes
      t.timestamps
    end
    # Uma conferência aberta por empresa.
    add_index :stock_counts, :company_id, unique: true, where: "status = 0", name: "index_stock_counts_one_open_per_company"

    create_table :stock_count_items do |t|
      t.references :stock_count, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :expected_quantity, precision: 12, scale: 3, null: false
      t.decimal :counted_quantity, precision: 12, scale: 3
      t.decimal :difference, precision: 12, scale: 3
      t.timestamps
    end
    add_index :stock_count_items, [ :stock_count_id, :product_id ], unique: true

    create_table :stock_movements do |t|
      t.references :company, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :source, polymorphic: true
      t.integer :kind, null: false
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.decimal :unit_cost, precision: 12, scale: 4
      t.string :reason
      t.text :notes
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :stock_movements, [ :product_id, :occurred_at ]
  end
end
