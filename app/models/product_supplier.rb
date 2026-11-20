# Fornecedor de um produto, com o último preço pago (atualizado a cada entrada).
class ProductSupplier < ApplicationRecord
  include BrazilianDecimal
  brazilian_decimal :last_price

  belongs_to :product, inverse_of: :product_suppliers
  belongs_to :supplier

  validates :supplier_id, uniqueness: { scope: :product_id }
  validates :last_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :same_company

  private

  def same_company
    return if product.nil? || supplier.nil?

    errors.add(:supplier, "não pertence a esta empresa") if supplier.company_id != product.company_id
  end
end
