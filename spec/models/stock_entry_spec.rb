require "rails_helper"

RSpec.describe StockEntry, type: :model do
  let(:user) { create(:user) }
  let(:company) { user.company }
  let(:supplier) { create(:supplier, company: company) }
  let(:account) { company.accounts.find_by!(name: "Caixa Dinheiro") }
  let(:subcategory) { company.subcategories.find_by!(name: "Hortifruti") }
  let(:product) { create(:product, company: company) }

  def build_entry(attrs = {})
    company.stock_entries.new({ supplier: supplier, account: account, subcategory: subcategory, creator: user,
                                received_on: Date.current, payment_method: "pix",
                                items_attributes: [ { product_id: product.id, quantity: "2,5", unit_cost: "4,00" } ] }.merge(attrs))
  end

  it { should belong_to(:company) }
  it { should belong_to(:supplier) }
  it { should belong_to(:account) }
  it { should belong_to(:subcategory) }
  it { should belong_to(:movement).optional }
  it { should belong_to(:creator).class_name("User").without_validating_presence }
  it { should validate_presence_of(:creator).on(:create) }
  it { should have_many(:items).dependent(:destroy) }

  it "computes item totals and the entry total" do
    entry = build_entry(items_attributes: [ { product_id: product.id, quantity: "2,5", unit_cost: "4,00" },
                                            { product_id: create(:product, company: company).id, quantity: 1, unit_cost: "1.234,50" } ])
    expect(entry).to be_valid
    expect(entry.items.map(&:total)).to eq([ 10, 1234.5 ])
    expect(entry.total).to eq(1244.5)
  end

  it "requires at least one item" do
    entry = build_entry(items_attributes: [])
    expect(entry).not_to be_valid
    expect(entry.errors[:items]).to be_present
  end

  it "ignores fully blank item rows" do
    entry = build_entry(items_attributes: [ { product_id: product.id, quantity: 1, unit_cost: 1 }, { product_id: "", quantity: "", unit_cost: "" } ])
    expect(entry.items.size).to eq(1)
  end

  it "requires a due date for boleto" do
    expect(build_entry(payment_method: "boleto")).not_to be_valid
    expect(build_entry(payment_method: "boleto", due_on: Date.current + 15)).to be_valid
  end

  it "requires an expense subcategory" do
    entry = build_entry(subcategory: company.subcategories.find_by!(name: "Pix"))
    expect(entry).not_to be_valid
    expect(entry.errors[:subcategory]).to be_present
  end

  it "rejects supplier, account, subcategory or product from another company" do
    other = create(:company)
    expect(build_entry(supplier: create(:supplier, company: other))).not_to be_valid
    expect(build_entry(account: other.accounts.first)).not_to be_valid
    expect(build_entry(subcategory: other.subcategories.find_by!(name: "Hortifruti"))).not_to be_valid
    expect(build_entry(items_attributes: [ { product_id: create(:product, company: other).id, quantity: 1, unit_cost: 1 } ])).not_to be_valid
  end

  it "requires positive quantity and non-negative cost on items" do
    expect(build_entry(items_attributes: [ { product_id: product.id, quantity: 0, unit_cost: 1 } ])).not_to be_valid
    expect(build_entry(items_attributes: [ { product_id: product.id, quantity: 1, unit_cost: -1 } ])).not_to be_valid
  end
end
