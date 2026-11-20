# Valor do estoque ao finalizar a conferência; é o estoque final de um período de CMV
# e o estoque inicial do seguinte.
class AddClosingValueToStockCounts < ActiveRecord::Migration[8.1]
  def change
    add_column :stock_counts, :closing_value, :decimal, precision: 14, scale: 2
  end
end
