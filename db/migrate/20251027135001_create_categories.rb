class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name
      t.boolean :is_income, null: false, default: false
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
  end
end
