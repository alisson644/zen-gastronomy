# Empresas criadas antes do seed gravar `is_income: true` ficaram com a categoria
# "Entrada de caixa" marcada como despesa, e o modal de transação não deixava
# escolher nenhuma categoria para o tipo Entrada.
class MarkLegacyIncomeCategories < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE categories SET is_income = TRUE
      WHERE name = 'Entrada de caixa' AND is_income = FALSE
    SQL
  end

  def down
    # Irreversível de propósito: não há como saber quais linhas estavam erradas.
  end
end
