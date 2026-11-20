class StockEntryItem < ApplicationRecord
  include BrazilianDecimal
  brazilian_decimal :quantity, :unit_cost

  belongs_to :stock_entry, inverse_of: :items
  belongs_to :product
  has_one :stock_movement, as: :source, dependent: :nullify

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }

  def compute_total
    self.total = (quantity * unit_cost).round(2) if quantity.is_a?(Numeric) && unit_cost.is_a?(Numeric)
  end
end
