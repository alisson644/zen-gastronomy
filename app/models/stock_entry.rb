# Compra recebida de um fornecedor. É gravada por StockEntryRegistration, que também
# dá entrada nos produtos e lança a saída no financeiro (pendente quando é boleto).
class StockEntry < ApplicationRecord
  PAYMENT_METHODS = { "dinheiro" => "Dinheiro", "pix" => "Pix", "cartao" => "Cartão",
                      "transferencia" => "Transferência", "boleto" => "Boleto" }.freeze

  belongs_to :company
  belongs_to :supplier
  belongs_to :account
  belongs_to :subcategory
  belongs_to :movement, optional: true
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id, optional: true
  has_many :items, class_name: "StockEntryItem", dependent: :destroy, inverse_of: :stock_entry

  enum :payment_method, { dinheiro: 0, pix: 1, cartao: 2, transferencia: 3, boleto: 4 }, validate: true

  accepts_nested_attributes_for :items,
                                reject_if: ->(attrs) { attrs.slice("product_id", "quantity", "unit_cost").values.all?(&:blank?) }

  before_validation :compute_total

  validates :received_on, presence: true
  validates :creator, presence: true, on: :create
  validates :due_on, presence: true, if: :boleto?
  validates :items, presence: { message: "adicione ao menos um produto" }
  validate :references_belong_to_company
  validate :subcategory_is_expense

  scope :recent, -> { order(received_on: :desc, id: :desc) }

  def payment_method_label = PAYMENT_METHODS[payment_method]

  def description_for_movement
    [ "Compra estoque", ("NF #{invoice_number}" if invoice_number.present?), "– #{supplier&.name}" ].compact.join(" ")
  end

  private

  def compute_total
    items.each(&:compute_total)
    self.total = items.reject(&:marked_for_destruction?).sum { |item| item.total || 0 }
  end

  def references_belong_to_company
    { supplier: supplier, account: account, subcategory: subcategory }.each do |name, record|
      errors.add(name, "não pertence a esta empresa") if record && record.company_id != company_id
    end
    if items.any? { |item| item.product && item.product.company_id != company_id }
      errors.add(:items, "contém produto de outra empresa")
    end
  end

  def subcategory_is_expense
    errors.add(:subcategory, "deve ser uma categoria de despesa") if subcategory&.category&.is_income
  end
end
