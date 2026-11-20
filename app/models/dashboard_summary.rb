# Agrega as movimentações de uma empresa para o dashboard.
# Considera apenas entradas e saídas (transferências entre contas não são receita nem despesa).
class DashboardSummary
  MONTH_NAMES = %w[Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro].freeze
  SHORT_MONTH_NAMES = %w[jan fev mar abr mai jun jul ago set out nov dez].freeze
  MAX_RANKED_ITEMS = 8

  attr_reader :company, :month

  def initialize(company, month: Date.current)
    @company = company
    @month = month.to_date.beginning_of_month
  end

  def self.parse_month(value)
    Date.strptime(value.to_s, "%Y-%m")
  rescue ArgumentError, TypeError
    Date.current
  end

  def month_label(date = month)
    "#{MONTH_NAMES[date.month - 1]} de #{date.year}"
  end

  def previous_month = month.prev_month
  def next_month = month.next_month
  def current_month? = month == Date.current.beginning_of_month

  # ---------- KPIs ----------
  def income_total(date = month)  = movements_in(date).entrada.sum(:amount)
  def expense_total(date = month) = movements_in(date).saida.sum(:amount)
  def result(date = month)        = income_total(date) - expense_total(date)
  def total_balance               = company.accounts.sum(:current_balance)

  # Variação percentual em relação ao mês anterior (nil quando não há base de comparação)
  def change(metric)
    current = public_send(metric)
    previous = public_send(metric, previous_month)
    return nil if previous.zero?

    ((current - previous) / previous * 100).round
  end

  # ---------- Rankings do mês ----------
  def expenses_by_category
    ranked(movements_in(month).saida.joins(:category).group("categories.name").sum(:amount))
  end

  def income_by_subcategory
    ranked(movements_in(month).entrada.joins(:subcategory).group("subcategories.name").sum(:amount))
  end

  # ---------- Série dos últimos N meses ----------
  # => [{ month: Date, label: "nov/26", income: BigDecimal, expense: BigDecimal }, ...]
  def monthly_series(months: 6)
    first = month.advance(months: -(months - 1))
    rows = company.movements.pago
                  .where(mv_type: %w[entrada saida], occurred_at: first.beginning_of_day..month.end_of_month.end_of_day)
                  .pluck(:occurred_at, :mv_type, :amount)

    totals = Hash.new { |h, k| h[k] = { "entrada" => 0.to_d, "saida" => 0.to_d } }
    rows.each { |occurred_at, type, amount| totals[occurred_at.in_time_zone.to_date.beginning_of_month][type] += amount }

    (0...months).map do |i|
      date = first.advance(months: i)
      { month: date, label: "#{SHORT_MONTH_NAMES[date.month - 1]}/#{date.strftime('%y')}",
        income: totals[date]["entrada"], expense: totals[date]["saida"] }
    end
  end

  private

  def movements_in(date)
    company.movements.pago.where(occurred_at: date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day)
  end

  # Ordena do maior para o menor e agrupa a cauda em "Outros"
  def ranked(totals)
    sorted = totals.sort_by { |_name, value| -value }
    return sorted if sorted.size <= MAX_RANKED_ITEMS

    head = sorted.first(MAX_RANKED_ITEMS - 1)
    head + [ [ "Outros", sorted.drop(MAX_RANKED_ITEMS - 1).sum { |_name, value| value } ] ]
  end
end
