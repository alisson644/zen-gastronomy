class ChangeCompanyIdfromUser < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :company_id
    add_reference :users, :company, null: true, foreign_key: true
  end
end
