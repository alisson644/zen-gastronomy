# Conferência de estoque: tira uma foto das quantidades (expected_quantity), o usuário
# informa o que contou, e ao finalizar o estoque é ajustado para o contado.
class StockCount < ApplicationRecord
  belongs_to :company
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id, optional: true
  belongs_to :finisher, class_name: "User", foreign_key: :finished_by_id, optional: true
  has_many :items, class_name: "StockCountItem", dependent: :destroy, inverse_of: :stock_count

  enum :status, { aberta: 0, finalizada: 1 }

  accepts_nested_attributes_for :items

  validates :creator, presence: true, on: :create
  validate :one_open_per_company, if: :aberta?

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def self.start!(company:, user:)
    transaction do
      count = company.stock_counts.create!(creator: user)
      company.products.active.ordered.each do |product|
        count.items.create!(product: product, expected_quantity: product.quantity)
      end
      count
    end
  end

  def finalize!(user)
    transaction do
      lock!
      unless aberta?
        errors.add(:base, "Conferência já finalizada")
        raise ActiveRecord::RecordInvalid, self
      end

      items.includes(:product).where.not(counted_quantity: nil).find_each { |item| adjust!(item, user) }
      update!(status: :finalizada, finished_at: Time.current, finisher: user)
    end
  end

  private

  def adjust!(item, user)
    current = Product.where(id: item.product_id).pick(:quantity)
    difference = item.counted_quantity - current
    item.update_columns(difference: difference)
    return if difference.zero?

    company.stock_movements.create!(product: item.product, kind: :ajuste, quantity: difference,
                                    unit_cost: item.product.average_cost, source: item, creator: user)
  end

  def one_open_per_company
    scope = StockCount.aberta.where(company_id: company_id)
    scope = scope.where.not(id: id) if persisted?
    errors.add(:base, "Já existe uma conferência aberta") if scope.exists?
  end
end
