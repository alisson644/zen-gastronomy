class AddAccountRefNameToMovement < ActiveRecord::Migration[8.0]
  def change
    add_reference :movements, :related_account, foreign_key: { to_table: :accounts, on_delete: :nullify }
  end
end
