# Item de estoque. `quantity` e `average_cost` são mantidos pelos StockMovement
# (nunca altere direto); o preço pago a cada fornecedor fica em ProductSupplier.
class Product < ApplicationRecord
  include BrazilianDecimal
  brazilian_decimal :sale_price, :min_quantity

  UNITS = {
    "un" => "Unidade", "kg" => "Quilo", "g" => "Grama", "l" => "Litro",
    "ml" => "Mililitro", "cx" => "Caixa", "pct" => "Pacote"
  }.freeze

  belongs_to :company
  # Categoria do financeiro sugerida nas entradas deste produto.
  belongs_to :subcategory, optional: true
  has_many :product_suppliers, dependent: :destroy, inverse_of: :product
  has_many :suppliers, through: :product_suppliers
  has_many :stock_movements, dependent: :restrict_with_error
  has_many :stock_entry_items, dependent: :restrict_with_error

  accepts_nested_attributes_for :product_suppliers, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["id"].blank? && attrs["supplier_id"].blank? }

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :unit, inclusion: { in: UNITS.keys }
  validates :sale_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :min_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :subcategory_is_company_expense

  scope :ordered, -> { order(:name) }
  scope :active, -> { where(active: true) }

  def unit_label = UNITS.fetch(unit, unit)

  def low_stock?
    min_quantity.present? && quantity <= min_quantity
  end

  def stock_value
    quantity * average_cost
  end

  private

  def subcategory_is_company_expense
    return if subcategory.nil?

    if subcategory.company_id != company_id
      errors.add(:subcategory, "não pertence a esta empresa")
    elsif subcategory.category.is_income
      errors.add(:subcategory, "deve ser uma categoria de despesa")
    end
  end
end
