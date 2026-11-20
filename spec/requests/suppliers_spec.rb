require "rails_helper"

RSpec.describe "Suppliers", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }
  let!(:supplier) { create(:supplier, company: company, name: "Ceasa Central") }

  before { sign_in user }

  it "lists only the company's suppliers" do
    create(:supplier, name: "Fornecedor de outra empresa")
    get suppliers_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ceasa Central")
    expect(response.body).not_to include("Fornecedor de outra empresa")
  end

  it "shows a supplier with its products" do
    create(:product_supplier, product: create(:product, company: company, name: "Alface"), supplier: supplier)
    get supplier_path(supplier)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ceasa Central", "Alface")
  end

  it "renders the new and edit forms" do
    get new_supplier_path
    expect(response).to have_http_status(:ok)
    get edit_supplier_path(supplier)
    expect(response).to have_http_status(:ok)
  end

  it "creates a supplier" do
    expect {
      post suppliers_path, params: { supplier: { name: "Atacadão", cnpj: "12.345.678/0001-00", contact_name: "Ana",
                                                 phone: "(11) 3333-4444", email: "ana@atacadao.com", notes: "Entrega terça" } }
    }.to change(company.suppliers, :count).by(1)
    expect(response).to redirect_to(suppliers_path)
    expect(company.suppliers.find_by!(name: "Atacadão").contact_name).to eq("Ana")
  end

  it "re-renders the form on invalid data" do
    post suppliers_path, params: { supplier: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "updates a supplier" do
    patch supplier_path(supplier), params: { supplier: { name: "Ceasa Norte" } }
    expect(response).to redirect_to(suppliers_path)
    expect(supplier.reload.name).to eq("Ceasa Norte")
  end

  it "destroys a supplier without entries" do
    expect { delete supplier_path(supplier) }.to change(Supplier, :count).by(-1)
    expect(response).to redirect_to(suppliers_path)
  end

  it "does not destroy a supplier with stock entries" do
    product = create(:product, company: company)
    entry = company.stock_entries.new(supplier: supplier, account: company.accounts.first, creator: user,
                                      subcategory: company.subcategories.find_by!(name: "Hortifruti"),
                                      received_on: Date.current, payment_method: "pix",
                                      items_attributes: [ { product_id: product.id, quantity: 1, unit_cost: 1 } ])
    StockEntryRegistration.new(entry).save
    expect { delete supplier_path(supplier) }.not_to change(Supplier, :count)
    expect(flash[:alert]).to be_present
  end

  it "cannot reach another company's supplier" do
    other = create(:supplier)
    get supplier_path(other)
    expect(response).to have_http_status(:not_found)

    sign_in user # a resposta 404 não regrava o cookie de sessão
    patch supplier_path(other), params: { supplier: { name: "Hack" } }
    expect(response).to have_http_status(:not_found)
    expect(other.reload.name).not_to eq("Hack")
  end
end
