require "rails_helper"

RSpec.describe Product, type: :model do
  subject { build(:product) }

  it { should belong_to(:company) }
  it { should belong_to(:subcategory).optional }
  it { should have_many(:product_suppliers).dependent(:destroy) }
  it { should have_many(:suppliers).through(:product_suppliers) }
  it { should have_many(:stock_movements).dependent(:restrict_with_error) }
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).scoped_to(:company_id) }
  it { should validate_inclusion_of(:unit).in_array(Product::UNITS.keys) }
  it { should validate_numericality_of(:sale_price).is_greater_than_or_equal_to(0).allow_nil }
  it { should validate_numericality_of(:min_quantity).is_greater_than_or_equal_to(0).allow_nil }

  let(:company) { create(:company) }

  it "starts with zero quantity and zero average cost" do
    product = create(:product, company: company)
    expect(product.quantity).to eq(0)
    expect(product.average_cost).to eq(0)
  end

  it "parses Brazilian decimals in the sale price and minimum quantity" do
    product = build(:product, sale_price: "1.234,56", min_quantity: "2,5")
    expect(product.sale_price).to eq(1234.56)
    expect(product.min_quantity).to eq(2.5)
  end

  it "flags low stock when the quantity reaches the minimum" do
    product = build(:product, min_quantity: 5, quantity: 5)
    expect(product).to be_low_stock
    product.quantity = 6
    expect(product).not_to be_low_stock
    product.min_quantity = nil
    expect(product).not_to be_low_stock
  end

  it "values the stock at average cost" do
    expect(build(:product, quantity: 3, average_cost: 2.5).stock_value).to eq(7.5)
  end

  it "accepts only an expense subcategory of its own company" do
    expense = company.subcategories.find_by!(name: "Hortifruti")
    income = company.subcategories.find_by!(name: "Pix")
    other = create(:company).subcategories.find_by!(name: "Hortifruti")

    expect(build(:product, company: company, subcategory: expense)).to be_valid
    expect(build(:product, company: company, subcategory: income)).not_to be_valid
    expect(build(:product, company: company, subcategory: other)).not_to be_valid
  end

  it "keeps several suppliers with their prices through nested attributes" do
    a = create(:supplier, company: company)
    b = create(:supplier, company: company)
    product = company.products.create!(name: "Tomate", unit: "kg", product_suppliers_attributes: [
      { supplier_id: a.id, last_price: "4,50", supplier_code: "TOM-1" },
      { supplier_id: b.id, last_price: "5,10" },
      { supplier_id: "" }
    ])
    expect(product.suppliers).to contain_exactly(a, b)
    expect(product.product_suppliers.find_by(supplier: a).last_price).to eq(4.5)
  end

  it "rejects a supplier from another company" do
    foreign = create(:supplier)
    product = company.products.new(name: "Tomate", unit: "kg", product_suppliers_attributes: [ { supplier_id: foreign.id } ])
    expect(product).not_to be_valid
  end

  it "cannot be destroyed once it has stock history" do
    user = create(:user, company: company)
    product = create(:product, company: company)
    company.stock_movements.create!(product: product, kind: :entrada, quantity: 1, unit_cost: 1, creator: user)
    expect(product.destroy).to be false
    expect(product.errors[:base]).to be_present
  end
end
