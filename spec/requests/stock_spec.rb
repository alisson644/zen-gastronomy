require "rails_helper"

RSpec.describe "Stock overview", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }

  before { sign_in user }

  it "lists products with quantity, value and low-stock alert" do
    rice = create(:product, company: company, name: "Arroz", min_quantity: 5)
    create(:product, name: "Produto de outra empresa")
    company.stock_movements.create!(product: rice, kind: :entrada, quantity: 3, unit_cost: 5, creator: user)

    get stock_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Arroz", "Estoque baixo", "R$ 15,00")
    expect(response.body).not_to include("Produto de outra empresa")
  end

  it "shows shortcuts for the actions the user can do" do
    get stock_path
    expect(response.body).to include(products_path, suppliers_path, new_stock_entry_path, new_stock_output_path, stock_counts_path)
  end

  it "adds Estoque to the sidebar" do
    get stock_path
    expect(response.body).to include(%(title="Estoque"))
  end

  describe "CMV" do
    let!(:product) { create(:product, company: company, name: "Arroz") }
    let(:income_sub) { company.subcategories.find_by!(name: "Pix") }

    def close_count(counted)
      count = StockCount.start!(company: company, user: user)
      count.items.find_by!(product: product).update!(counted_quantity: counted)
      count.finalize!(user)
      count
    end

    it "explains that two counts are needed" do
      travel_to(Time.zone.parse("2026-11-01 22:00")) { close_count(0) }
      get stock_path
      expect(response.body).to include("Finalize duas conferências para calcular o CMV")
    end

    it "shows the CMV of the last period and its share of the revenue" do
      travel_to(Time.zone.parse("2026-10-20 10:00")) do
        company.stock_movements.create!(product: product, kind: :entrada, quantity: 10, unit_cost: 5, creator: user)
      end
      travel_to(Time.zone.parse("2026-11-01 22:00")) { close_count(10) }          # inicial 50
      travel_to(Time.zone.parse("2026-11-10 10:00")) do
        entry = company.stock_entries.new(supplier: create(:supplier, company: company), account: company.accounts.first,
                                          subcategory: company.subcategories.find_by!(name: "Hortifruti"), creator: user,
                                          received_on: Date.current, payment_method: "pix",
                                          items_attributes: [ { product_id: product.id, quantity: 20, unit_cost: 5 } ])
        StockEntryRegistration.new(entry).save || raise(entry.errors.full_messages.to_sentence)
      end                                                                         # compras 100
      company.movements.create!(mv_type: :entrada, amount: 800, occurred_at: Date.new(2026, 11, 15), account: company.accounts.first,
                                subcategory: income_sub, category: income_sub.category, creator: user)
      travel_to(Time.zone.parse("2026-11-30 22:00")) { close_count(22) }          # final 110 → CMV 40 = 5%

      get stock_path
      expect(response.body).to include("CMV", "01/11/2026", "30/11/2026", "R$ 50,00", "R$ 100,00", "R$ 110,00", "R$ 40,00", "5,0%", "R$ 800,00")
      expect(response.body).not_to include("Finalize duas conferências")
    end
  end
end
