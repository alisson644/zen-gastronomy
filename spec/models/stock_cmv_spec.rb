require "rails_helper"

RSpec.describe StockCmv do
  let(:user) { create(:user) }
  let(:company) { user.company }
  let(:account) { company.accounts.create!(name: "Banco", account_type: :banco, initial_balance: 10_000, current_balance: 10_000) }
  let(:supplier) { create(:supplier, company: company) }
  let(:food_sub) { company.subcategories.find_by!(name: "Hortifruti") }
  let(:income_sub) { company.subcategories.find_by!(name: "Pix") }
  let!(:rice) { create(:product, company: company, name: "Arroz") }

  def at(time, &block) = travel_to(Time.zone.parse(time), &block)

  def purchase(quantity, unit_cost)
    entry = company.stock_entries.new(supplier: supplier, account: account, subcategory: food_sub, creator: user,
                                      received_on: Date.current, payment_method: "pix",
                                      items_attributes: [ { product_id: rice.id, quantity: quantity, unit_cost: unit_cost } ])
    StockEntryRegistration.new(entry).save || raise(entry.errors.full_messages.to_sentence)
  end

  def sale(amount, date, **attrs)
    company.movements.create!({ mv_type: :entrada, amount: amount, occurred_at: date, account: account,
                                subcategory: income_sub, category: income_sub.category, creator: user }.merge(attrs))
  end

  def close_count(counted)
    count = StockCount.start!(company: company, user: user)
    count.items.find_by!(product: rice).update!(counted_quantity: counted)
    count.finalize!(user)
    count
  end

  context "with two finalized counts" do
    let!(:first_count) do
      at("2026-10-20 10:00") { company.stock_movements.create!(product: rice, kind: :entrada, quantity: 10, unit_cost: 5, creator: user) }
      at("2026-11-01 22:00") { close_count(10) } # estoque inicial 10 x 5 = 50
    end

    let!(:second_count) do
      at("2026-11-10 09:00") { purchase(20, 5) } # compras 100
      at("2026-11-12 09:00") { company.stock_movements.create!(product: rice, kind: :saida, quantity: 5, reason: "perda", creator: user) }
      at("2026-11-30 22:00") { close_count(22) } # estoque final 22 x 5 = 110
    end

    subject(:period) { described_class.for_count(second_count) }

    before do
      sale(1000, Date.new(2026, 11, 15))
      sale(600, Date.new(2026, 11, 30))      # dia da conferência: entra
      sale(999, Date.new(2026, 11, 1))       # dia da conferência anterior: também entra
      sale(888, Date.new(2026, 12, 1))       # depois do período
      sale(777, Date.new(2026, 10, 31))      # antes do período
    end

    it "computes opening stock + purchases - closing stock" do
      expect(period.start_date).to eq(Date.new(2026, 11, 1))
      expect(period.end_date).to eq(Date.new(2026, 11, 30))
      expect(period.opening_value).to eq(50)
      expect(period.purchases).to eq(100)
      expect(period.closing_value).to eq(110)
      expect(period.cmv).to eq(40)
    end

    it "relates the CMV to the paid revenue of the period" do
      expect(period.revenue).to eq(2599)
      expect(period.cmv_percent).to eq(1.5)
    end

    it "ignores expenses and transfers in the revenue" do
      other = company.accounts.create!(name: "Outra", account_type: :banco, initial_balance: 0, current_balance: 0)
      company.movements.create!(mv_type: :transfer, amount: 500, occurred_at: Date.new(2026, 11, 20), account: account,
                                related_account: other, creator: user)
      expect(period.revenue).to eq(2599)
    end

    it "excludes purchases registered outside the period" do
      at("2026-12-02 10:00") { purchase(1, 5) }
      expect(described_class.for_count(second_count).purchases).to eq(100)
    end

    it "has no CMV percent without revenue" do
      Movement.entrada.delete_all
      expect(described_class.for_count(second_count).cmv_percent).to be_nil
    end

    it "has no period for the first count" do
      expect(described_class.for_count(first_count)).to be_nil
    end

    it "lists periods newest first, respecting the limit" do
      third = at("2026-12-31 22:00") { close_count(20) }
      periods = described_class.periods(company)
      expect(periods.map(&:end_count)).to eq([ third, second_count ])
      expect(described_class.periods(company, limit: 1).map(&:end_count)).to eq([ third ])
    end

    it "skips counts finalized without a closing value" do
      first_count.update_column(:closing_value, nil)
      expect(described_class.periods(company)).to be_empty
      expect(described_class.for_count(second_count)).to be_nil
    end
  end

  it "counts the revenue of the day when both counts close on the same day" do
    at("2026-11-23 11:50") { close_count(0) }
    second = at("2026-11-23 11:51") { close_count(0) }
    sale(5000, Date.new(2026, 11, 23))

    period = described_class.for_count(second)
    expect(period.start_date).to eq(Date.new(2026, 11, 23))
    expect(period.end_date).to eq(Date.new(2026, 11, 23))
    expect(period.revenue).to eq(5000)
  end

  it "has no periods with a single count" do
    close_count(0)
    expect(described_class.periods(company)).to be_empty
  end

  it "ignores open counts" do
    StockCount.start!(company: company, user: user)
    expect(described_class.periods(company)).to be_empty
  end
end
