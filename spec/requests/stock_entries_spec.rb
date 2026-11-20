require "rails_helper"

RSpec.describe "Stock entries", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }
  let!(:supplier) { create(:supplier, company: company, name: "Ceasa") }
  let!(:account) { company.accounts.create!(name: "Banco", account_type: :banco, initial_balance: 500, current_balance: 500) }
  let(:subcategory) { company.subcategories.find_by!(name: "Hortifruti") }
  let!(:product) { create(:product, company: company, name: "Tomate", subcategory: subcategory) }

  before { sign_in user }

  def entry_params(attrs = {})
    { supplier_id: supplier.id, account_id: account.id, subcategory_id: subcategory.id, received_on: Date.current.to_s,
      payment_method: "pix", invoice_number: "999",
      items_attributes: { "0" => { product_id: product.id, quantity: "10", unit_cost: "3,50" } } }.merge(attrs)
  end

  it "renders the form with the company's data" do
    create(:supplier, name: "Fornecedor alheio")
    get new_stock_entry_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ceasa", "Tomate", "Banco", "Hortifruti", "Boleto", 'data-controller="stock-entry nested-fields"')
    expect(response.body).not_to include("Fornecedor alheio")
  end

  it "registers the entry, the stock and the paid expense" do
    expect { post stock_entries_path, params: { stock_entry: entry_params } }.to change(company.stock_entries, :count).by(1)
    entry = company.stock_entries.last
    expect(response).to redirect_to(stock_entry_path(entry))
    expect(entry.creator).to eq(user)
    expect(product.reload.quantity).to eq(10)
    expect(entry.movement).to be_pago
    expect(account.reload.current_balance).to eq(465)
  end

  it "registers a boleto as a pending expense on the due date" do
    due = Date.current + 30
    post stock_entries_path, params: { stock_entry: entry_params(payment_method: "boleto", due_on: due.to_s) }
    entry = company.stock_entries.last
    expect(entry.movement).to be_pendente
    expect(entry.movement.occurred_at.to_date).to eq(due)
    expect(account.reload.current_balance).to eq(500)

    get financial_index_path
    expect(response.body).to include("Pendente", pay_movement_path(entry.movement))
  end

  it "re-renders the form when invalid" do
    expect {
      post stock_entries_path, params: { stock_entry: entry_params(payment_method: "boleto") }
    }.not_to change(StockEntry, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(Movement.count).to eq(0)
  end

  it "ignores ids from another company" do
    other = create(:company)
    post stock_entries_path, params: { stock_entry: entry_params(account_id: other.accounts.first.id) }
    expect(response).to have_http_status(:unprocessable_content)
    post stock_entries_path, params: { stock_entry: entry_params(supplier_id: create(:supplier, company: other).id) }
    expect(response).to have_http_status(:unprocessable_content)
    expect(StockEntry.count).to eq(0)
  end

  it "lists and shows entries" do
    post stock_entries_path, params: { stock_entry: entry_params }
    entry = company.stock_entries.last
    get stock_entries_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ceasa", "999")
    get stock_entry_path(entry)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Tomate", "R$ 35,00")
  end

  it "cannot see another company's entry" do
    post stock_entries_path, params: { stock_entry: entry_params }
    entry = company.stock_entries.last
    sign_in create(:user)
    get stock_entry_path(entry)
    expect(response).to have_http_status(:not_found)
  end

  describe "creating categories from the form" do
    it "offers the category and subcategory modals" do
      get new_stock_entry_path
      expect(response.body).to include('commandfor="category"', 'commandfor="subcategory"', 'id="stock_entry_subcategory_select"')
      expect(response.body).to include('name="expense_only"')
    end

    it "hides them without the categories permission" do
      role = create(:role, company: company, permissions: %w[stock.entries])
      sign_in create(:user, company: company, role: role)
      get new_stock_entry_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('commandfor="category"')
    end
  end
end
