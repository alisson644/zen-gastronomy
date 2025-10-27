class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :name
      t.integer :account_type
      t.decimal :current_balance
      t.decimal :initial_balance

      t.timestamps
    end
  end
end
