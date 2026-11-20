# Movimentações pendentes (boletos ainda não pagos) não afetam o saldo das contas.
# A coluna status existia sem uso: passa a ser 0 = pendente, 1 = pago.
class AddPaymentStatusToMovements < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE movements SET status = 1 WHERE status IS NULL"
    change_column_default :movements, :status, 1
    change_column_null :movements, :status, false
    add_column :movements, :paid_at, :datetime
    add_index :movements, :status
  end

  def down
    remove_index :movements, :status
    remove_column :movements, :paid_at
    change_column_null :movements, :status, true
    change_column_default :movements, :status, nil
  end
end
