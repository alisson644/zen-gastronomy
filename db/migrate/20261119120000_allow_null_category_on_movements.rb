# Transfers move money between accounts and have no category/subcategory.
class AllowNullCategoryOnMovements < ActiveRecord::Migration[8.0]
  def change
    change_column_null :movements, :category_id, true
    change_column_null :movements, :subcategory_id, true
  end
end
