require "rails_helper"

RSpec.describe "Stock counts", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }
  let!(:product) { create(:product, company: company, name: "Arroz") }

  before do
    company.stock_movements.create!(product: product, kind: :entrada, quantity: 10, unit_cost: 5, creator: user)
    sign_in user
  end

  it "starts a count and lists it" do
    expect { post stock_counts_path }.to change(company.stock_counts, :count).by(1)
    count = company.stock_counts.last
    expect(response).to redirect_to(stock_count_path(count))

    get stock_counts_path
    expect(response).to have_http_status(:ok)
    get stock_count_path(count)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Arroz", "Finalizar")
  end

  it "redirects to the open count instead of starting another" do
    post stock_counts_path
    open_count = company.stock_counts.last
    expect { post stock_counts_path }.not_to change(StockCount, :count)
    expect(response).to redirect_to(stock_count_path(open_count))
  end

  it "saves counted quantities and finalizes adjusting the stock" do
    post stock_counts_path
    count = company.stock_counts.last
    item = count.items.first

    patch stock_count_path(count), params: { stock_count: { notes: "Contagem mensal", items_attributes: { "0" => { id: item.id, counted_quantity: "7,5" } } } }
    expect(response).to redirect_to(stock_count_path(count))
    expect(item.reload.counted_quantity).to eq(7.5)
    expect(product.reload.quantity).to eq(10)

    patch finalize_stock_count_path(count)
    expect(response).to redirect_to(stock_count_path(count))
    expect(count.reload).to be_finalizada
    expect(product.reload.quantity).to eq(7.5)

    get stock_count_path(count)
    expect(response.body).not_to include("Finalizar")
    expect(response.body).to include("-2,5")
  end

  it "does not edit a finalized count" do
    post stock_counts_path
    count = company.stock_counts.last
    count.finalize!(user)
    patch stock_count_path(count), params: { stock_count: { items_attributes: { "0" => { id: count.items.first.id, counted_quantity: "1" } } } }
    expect(response).to redirect_to(stock_count_path(count))
    expect(flash[:alert]).to be_present
    expect(count.items.first.reload.counted_quantity).to be_nil
  end

  it "cannot reach another company's count" do
    other_user = create(:user)
    other = StockCount.start!(company: other_user.company, user: other_user)
    get stock_count_path(other)
    expect(response).to have_http_status(:not_found)

    sign_in user # a resposta 404 não regrava o cookie de sessão
    patch finalize_stock_count_path(other)
    expect(response).to have_http_status(:not_found)
  end

  it "shows the closing value and the CMV of the period on a finalized count" do
    first = travel_to(Time.zone.parse("2026-11-01 22:00")) { StockCount.start!(company: company, user: user).tap { |c| c.finalize!(user) } }
    second = travel_to(Time.zone.parse("2026-11-30 22:00")) do
      StockCount.start!(company: company, user: user).tap do |count|
        count.items.first.update!(counted_quantity: 6)
        count.finalize!(user)
      end
    end

    get stock_count_path(first)
    expect(response.body).to include("Estoque final", "R$ 50,00")
    expect(response.body).not_to include("CMV do período")

    get stock_count_path(second)
    expect(response.body).to include("Estoque final", "R$ 30,00", "CMV do período", "R$ 20,00")
  end
end
