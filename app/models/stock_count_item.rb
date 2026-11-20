class StockCountItem < ApplicationRecord
  include BrazilianDecimal
  brazilian_decimal :counted_quantity

  belongs_to :stock_count, inverse_of: :items
  belongs_to :product

  validates :counted_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :count_is_open, on: :update

  # Diferença prevista enquanto a conferência está aberta; a definitiva é gravada ao finalizar.
  def preview_difference
    return difference if difference
    return if counted_quantity.nil?

    counted_quantity - expected_quantity
  end

  private

  def count_is_open
    errors.add(:base, "Conferência já finalizada") if stock_count.finalizada? && counted_quantity_changed?
  end
end
