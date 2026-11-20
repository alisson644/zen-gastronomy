require "rails_helper"

RSpec.describe "Products", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }
  let!(:supplier_a) { create(:supplier, company: company, name: "Ceasa") }
  let!(:supplier_b) { create(:supplier, company: company, name: "Atacadão") }
  let(:subcategory) { company.subcategories.find_by!(name: "Hortifruti") }

  before { sign_in user }

  def product_params(attrs = {})
    { name: "Tomate", code: "TOM", unit: "kg", min_quantity: "5", sale_price: "12,90", subcategory_id: subcategory.id,
      product_suppliers_attributes: {
        "0" => { supplier_id: supplier_a.id, supplier_code: "A-1", last_price: "4,50" },
        "1" => { supplier_id: supplier_b.id, last_price: "5,00" }
      } }.merge(attrs)
  end

  it "lists only the company's products" do
    create(:product, company: company, name: "Arroz")
    create(:product, name: "Produto de outra empresa")
    get products_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Arroz")
    expect(response.body).not_to include("Produto de outra empresa")
  end

  it "renders the form with the company's suppliers and expense subcategories" do
    create(:supplier, name: "Fornecedor alheio")
    get new_product_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ceasa", "Atacadão", "Hortifruti", 'data-controller="nested-fields"')
    expect(response.body).not_to include("Fornecedor alheio")
  end

  it "creates a product with several suppliers" do
    expect { post products_path, params: { product: product_params } }.to change(company.products, :count).by(1)
    product = company.products.find_by!(name: "Tomate")
    expect(response).to redirect_to(product_path(product))
    expect(product.sale_price).to eq(12.9)
    expect(product.suppliers).to contain_exactly(supplier_a, supplier_b)
    expect(product.product_suppliers.find_by!(supplier: supplier_a).supplier_code).to eq("A-1")
  end

  it "ignores a submitted quantity and average cost" do
    post products_path, params: { product: product_params(quantity: 99, average_cost: 7) }
    product = company.products.find_by!(name: "Tomate")
    expect(product.quantity).to eq(0)
    expect(product.average_cost).to eq(0)
  end

  it "re-renders the form on invalid data" do
    post products_path, params: { product: product_params(name: "") }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects a subcategory from another company" do
    foreign = create(:company).subcategories.find_by!(name: "Hortifruti")
    post products_path, params: { product: product_params(subcategory_id: foreign.id) }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "shows a product with its suppliers" do
    post products_path, params: { product: product_params }
    get product_path(company.products.find_by!(name: "Tomate"))
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Tomate", "Ceasa", "Atacadão")
  end

  it "updates the product and removes a supplier" do
    post products_path, params: { product: product_params }
    product = company.products.find_by!(name: "Tomate")
    link = product.product_suppliers.find_by!(supplier: supplier_b)

    get edit_product_path(product)
    expect(response).to have_http_status(:ok)

    patch product_path(product), params: { product: { name: "Tomate italiano",
      product_suppliers_attributes: { "0" => { id: link.id, _destroy: "1" } } } }
    expect(response).to redirect_to(product_path(product))
    expect(product.reload.name).to eq("Tomate italiano")
    expect(product.suppliers).to contain_exactly(supplier_a)
  end

  it "destroys a product without stock history" do
    product = create(:product, company: company)
    expect { delete product_path(product) }.to change(Product, :count).by(-1)
    expect(response).to redirect_to(products_path)
  end

  it "keeps a product with stock history and suggests deactivating it" do
    product = create(:product, company: company)
    company.stock_movements.create!(product: product, kind: :entrada, quantity: 1, unit_cost: 1, creator: user)
    expect { delete product_path(product) }.not_to change(Product, :count)
    expect(flash[:alert]).to include("desative")
  end

  it "cannot reach another company's product" do
    other = create(:product)
    get product_path(other)
    expect(response).to have_http_status(:not_found)

    sign_in user # a resposta 404 não regrava o cookie de sessão
    delete product_path(other)
    expect(response).to have_http_status(:not_found)
  end

  describe "creating categories from the form" do
    it "offers the category and subcategory modals" do
      get new_product_path
      expect(response.body).to include('commandfor="category"', 'commandfor="subcategory"', 'id="product_subcategory_select"')
      expect(response.body).to include('name="expense_only"')
    end

    it "hides them without the categories permission" do
      role = create(:role, company: company, permissions: %w[products.manage])
      sign_in create(:user, company: company, role: role)
      get new_product_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('commandfor="category"')
    end
  end
end
