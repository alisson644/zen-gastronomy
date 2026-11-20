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
end
