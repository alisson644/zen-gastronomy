require "rails_helper"

RSpec.describe "Stock outputs", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }
  let!(:product) { create(:product, company: company, name: "Arroz") }

  before do
    company.stock_movements.create!(product: product, kind: :entrada, quantity: 10, unit_cost: 5, creator: user)
    sign_in user
  end

  it "renders the form" do
    get new_stock_output_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Arroz", "Consumo", "Perda")
  end

  it "lowers the stock without touching the financial" do
    expect {
      post stock_outputs_path, params: { stock_movement: { product_id: product.id, quantity: "2,5", reason: "perda", notes: "caiu" } }
    }.not_to change(Movement, :count)
    expect(response).to redirect_to(stock_path)
    expect(product.reload.quantity).to eq(7.5)
    expect(company.stock_movements.saida.last.creator).to eq(user)
  end

  it "rejects more than the available quantity" do
    post stock_outputs_path, params: { stock_movement: { product_id: product.id, quantity: "11", reason: "consumo" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(product.reload.quantity).to eq(10)
  end

  it "rejects another company's product" do
    post stock_outputs_path, params: { stock_movement: { product_id: create(:product).id, quantity: "1", reason: "consumo" } }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
