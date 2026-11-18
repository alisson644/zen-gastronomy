class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :key
      t.boolean :system, null: false, default: false
      t.string :permissions, array: true, null: false, default: []

      t.timestamps
    end
    add_index :roles, :name, unique: true
    add_index :roles, :key, unique: true
  end
end
