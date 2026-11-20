# Grava uma entrada de estoque e seus efeitos numa única transação:
#   1. a StockEntry com os itens;
#   2. um StockMovement de entrada por item (atualiza quantidade e custo médio);
#   3. o último preço pago em ProductSupplier (cria o vínculo se ainda não existir);
#   4. a saída no financeiro — paga na data do recebimento, ou pendente no vencimento se for boleto.
#
#   entry = company.stock_entries.new(params.merge(creator: user))
#   StockEntryRegistration.new(entry).save # => true/false (erros em entry.errors)
class StockEntryRegistration
  attr_reader :entry

  def initialize(entry)
    @entry = entry
  end

  def save
    return false unless entry.valid?

    movement = build_movement
    unless movement.valid?
      movement.errors.full_messages.each { |message| entry.errors.add(:base, "Financeiro: #{message}") }
      return false
    end

    ActiveRecord::Base.transaction do
      entry.save!
      movement.save!
      entry.update_columns(movement_id: movement.id)
      entry.items.each { |item| register_item!(item) }
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    entry.errors.add(:base, e.record.errors.full_messages.to_sentence.presence || e.message)
    false
  end

  private

  def build_movement
    entry.company.movements.new(
      mv_type: :saida,
      amount: entry.total,
      account: entry.account,
      subcategory: entry.subcategory,
      category: entry.subcategory&.category,
      creator: entry.creator,
      status: entry.boleto? ? :pendente : :pago,
      paid_at: entry.boleto? ? nil : Time.current,
      occurred_at: entry.boleto? ? entry.due_on : entry.received_on,
      description: entry.description_for_movement
    )
  end

  def register_item!(item)
    entry.company.stock_movements.create!(
      product: item.product, kind: :entrada, quantity: item.quantity, unit_cost: item.unit_cost,
      source: item, creator: entry.creator, occurred_at: entry.received_on.in_time_zone
    )
    link = item.product.product_suppliers.find_or_initialize_by(supplier: entry.supplier)
    link.update!(last_price: item.unit_cost)
  end
end
