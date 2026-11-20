# CMV pelo método do inventário, entre duas conferências finalizadas consecutivas:
#
#   CMV = estoque inicial (fechamento da conferência anterior)
#       + compras (entradas registradas entre os dois fechamentos)
#       − estoque final (fechamento desta conferência)
#
# Consumo e perdas ficam embutidos no resultado. A primeira conferência só abre o ciclo.
# O faturamento considera as entradas pagas do dia seguinte à conferência anterior até o
# dia desta (presume conferência no fim do dia).
class StockCmv
  attr_reader :start_count, :end_count

  def self.periods(company, limit: 6)
    counts = closed_counts(company).limit(limit + 1).to_a
    counts.each_cons(2).map { |current, previous| new(previous, current) }
  end

  def self.for_count(count)
    return unless count.finalizada? && count.closing_value

    previous = closed_counts(count.company).where("finished_at < ?", count.finished_at).first
    new(previous, count) if previous
  end

  def self.closed_counts(company)
    company.stock_counts.finalizada.where.not(closing_value: nil).order(finished_at: :desc)
  end
  private_class_method :closed_counts

  def initialize(start_count, end_count)
    @start_count = start_count
    @end_count = end_count
  end

  def company = end_count.company
  def start_date = start_count.finished_at.to_date.next_day
  def end_date = end_count.finished_at.to_date
  def opening_value = start_count.closing_value
  def closing_value = end_count.closing_value

  def purchases
    @purchases ||= company.stock_entries
                          .where("stock_entries.created_at > ? AND stock_entries.created_at <= ?", start_count.finished_at, end_count.finished_at)
                          .sum(:total)
  end

  def cmv = opening_value + purchases - closing_value

  def revenue
    @revenue ||= company.movements.pago.entrada
                        .where(occurred_at: start_date.beginning_of_day..end_date.end_of_day)
                        .sum(:amount)
  end

  # Percentual do faturamento (nil quando não houve faturamento no período).
  def cmv_percent
    return nil if revenue.zero?

    (cmv / revenue * 100).round(1)
  end
end
