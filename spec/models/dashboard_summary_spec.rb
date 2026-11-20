require 'rails_helper'

RSpec.describe DashboardSummary do
  let(:user) { create(:user) }
  let(:company) { user.company }
  let(:account) { company.accounts.first }
  let(:other_account) { company.accounts.create!(name: "Banco", account_type: :banco, initial_balance: 0, current_balance: 0) }
  let(:month) { Date.new(2026, 11, 1) }
  let(:income_sub) { company.subcategories.find_by!(name: "Pix") }
  let(:expense_sub) { company.subcategories.find_by!(name: "Aluguel") }
  let(:food_sub) { company.subcategories.find_by!(name: "Hortifruti") }

  def mv(type, amount, date, sub, related: nil)
    company.movements.create!(mv_type: type, amount: amount, occurred_at: date, account: account,
                              subcategory: sub, category: sub.category, creator: user, related_account: related)
  end

  subject(:summary) { described_class.new(company, month: month) }

  before do
    mv(:entrada, 1000, Date.new(2026, 11, 3), income_sub)
    mv(:saida, 300, Date.new(2026, 11, 10), expense_sub)
    mv(:saida, 200, Date.new(2026, 11, 30), food_sub)
    mv(:transfer, 999, Date.new(2026, 11, 15), expense_sub, related: other_account)
    mv(:saida, 250, Date.new(2026, 10, 5), expense_sub)
    mv(:entrada, 400, Date.new(2026, 10, 5), income_sub)
    mv(:saida, 50, Date.new(2026, 12, 1), expense_sub) # mês seguinte, fora
  end

  it "sums income, expenses and result for the month ignoring transfers" do
    expect(summary.income_total).to eq(1000)
    expect(summary.expense_total).to eq(500)
    expect(summary.result).to eq(500)
  end

  it "compares with the previous month" do
    expect(summary.change(:expense_total)).to eq(100)  # 250 -> 500
    expect(summary.change(:income_total)).to eq(150)   # 400 -> 1000
  end

  it "returns nil change when the previous month is empty" do
    expect(described_class.new(company, month: Date.new(2026, 10, 1)).change(:income_total)).to be_nil
  end

  it "ranks expenses by category, largest first" do
    expect(summary.expenses_by_category).to eq([ [ "Custo com Ocupação", 300 ], [ "Despesas Variáveis - CMV", 200 ] ])
  end

  it "ranks income by subcategory" do
    expect(summary.income_by_subcategory).to eq([ [ "Pix", 1000 ] ])
  end

  it "builds a 6-month series ending in the selected month" do
    series = summary.monthly_series(months: 6)
    expect(series.map { |m| m[:label] }).to eq(%w[jun/26 jul/26 ago/26 set/26 out/26 nov/26])
    expect(series.last).to include(income: 1000, expense: 500)
    expect(series[-2]).to include(income: 400, expense: 250)
    expect(series.first).to include(income: 0, expense: 0)
  end

  it "folds the tail into 'Outros' when there are many categories" do
    totals = (1..10).to_h { |i| [ "Cat #{i}", i * 10 ] }
    ranked = summary.send(:ranked, totals)
    expect(ranked.size).to eq(DashboardSummary::MAX_RANKED_ITEMS)
    expect(ranked.last).to eq([ "Outros", 10 + 20 + 30 ])
  end

  it "parses the month param and falls back to the current month" do
    expect(described_class.parse_month("2026-03")).to eq(Date.new(2026, 3, 1))
    expect(described_class.parse_month("lixo")).to eq(Date.current)
  end

  it "ignores pending movements (unpaid boletos)" do
    company.movements.create!(mv_type: :saida, amount: 700, occurred_at: Date.new(2026, 11, 20), account: account,
                              subcategory: expense_sub, category: expense_sub.category, creator: user, status: :pendente)
    expect(summary.expense_total).to eq(500)
    expect(summary.monthly_series(months: 1).last).to include(expense: 500)
    expect(summary.expenses_by_category.to_h.values.sum).to eq(500)
  end
end
