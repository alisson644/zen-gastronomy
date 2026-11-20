# Livro-razão do estoque. `quantity` tem sinal: entrada > 0, saída < 0, ajuste ±.
# Ao ser criado, atualiza Product#quantity (e o custo médio nas entradas) com lock na linha,
# como Movement faz com o saldo das contas. Não é editado nem apagado.
class StockMovement < ApplicationRecord
  include BrazilianDecimal
  brazilian_decimal :quantity, :unit_cost

  REASONS = { "consumo" => "Consumo", "perda" => "Perda", "vencido" => "Vencido", "outro" => "Outro" }.freeze

  belongs_to :company
  belongs_to :product
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id, optional: true
  belongs_to :source, polymorphic: true, optional: true

  enum :kind, { entrada: 0, saida: 1, ajuste: 2 }

  before_validation :normalize_sign
  before_validation { self.occurred_at ||= Time.current }

  validates :kind, presence: true
  validates :creator, presence: true, on: :create
  validates :quantity, numericality: { other_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }, if: :entrada?
  validates :reason, inclusion: { in: REASONS.keys }, if: :saida?
  validate :product_belongs_to_company
  validate :output_within_stock, on: :create

  after_create :apply_to_product!

  scope :recent, -> { order(occurred_at: :desc, id: :desc) }

  def reason_label = REASONS[reason]

  private

  def normalize_sign
    return unless quantity.is_a?(Numeric)

    self.quantity = quantity.abs if entrada?
    self.quantity = -quantity.abs if saida?
  end

  def product_belongs_to_company
    errors.add(:product, "não pertence a esta empresa") if product && product.company_id != company_id
  end

  def output_within_stock
    return unless saida? && product && quantity.is_a?(Numeric)

    available = Product.where(id: product_id).pick(:quantity) || 0
    if available + quantity < 0
      errors.add(:quantity, "maior que o disponível em estoque (#{available.to_s('F')} #{product.unit})")
    end
  end

  def apply_to_product!
    locked = Product.lock.find(product_id)
    attrs = { quantity: locked.quantity + quantity }
    attrs[:average_cost] = new_average_cost(locked) if entrada?
    locked.update_columns(attrs.merge(updated_at: Time.current))
  end

  def new_average_cost(locked)
    return unit_cost if locked.quantity <= 0

    ((locked.quantity * locked.average_cost) + (quantity * unit_cost)) / (locked.quantity + quantity)
  end
end
