require "rails_helper"

RSpec.describe StockEntryRegistration do
  let(:user) { create(:user) }
  let(:company) { user.company }
  let(:supplier) { create(:supplier, company: company, name: "Ceasa") }
  let(:account) { company.accounts.create!(name: "Banco", account_type: :banco, initial_balance: 1000, current_balance: 1000) }
  let(:subcategory) { company.subcategories.find_by!(name: "Hortifruti") }
  let(:tomato) { create(:product, company: company, name: "Tomate") }
  let(:onion) { create(:product, company: company, name: "Cebola") }

  def build_entry(attrs = {})
    company.stock_entries.new({ supplier: supplier, account: account, subcategory: subcategory, creator: user,
                                received_on: Date.current, payment_method: "pix", invoice_number: "123",
                                items_attributes: [ { product_id: tomato.id, quantity: 10, unit_cost: 4 },
                                                    { product_id: onion.id, quantity: 5, unit_cost: 2 } ] }.merge(attrs))
  end

  def register(attrs = {})
    entry = build_entry(attrs)
    [ described_class.new(entry).save, entry ]
  end

  context "paid on receipt (pix)" do
    it "adds the products to the stock" do
      ok, = register
      expect(ok).to be true
      expect(tomato.reload.quantity).to eq(10)
      expect(tomato.average_cost).to eq(4)
      expect(onion.reload.quantity).to eq(5)
      expect(company.stock_movements.entrada.count).to eq(2)
    end

    it "creates a paid expense in the financial and debits the account" do
      _, entry = register
      movement = entry.reload.movement
      expect(movement).to be_saida
      expect(movement).to be_pago
      expect(movement.amount).to eq(50)
      expect(movement.account).to eq(account)
      expect(movement.subcategory).to eq(subcategory)
      expect(movement.category).to eq(subcategory.category)
      expect(movement.creator).to eq(user)
      expect(movement.occurred_at.to_date).to eq(Date.current)
      expect(movement.description).to include("NF 123", "Ceasa")
      expect(account.reload.current_balance).to eq(950)
    end

    it "links each stock movement to its entry item" do
      _, entry = register
      expect(entry.items.map { |item| item.stock_movement.quantity }).to contain_exactly(10, 5)
    end
  end

  context "paid with boleto" do
    it "creates a pending expense on the due date without touching the balance" do
      due = Date.current + 20
      _, entry = register(payment_method: "boleto", due_on: due)
      movement = entry.reload.movement
      expect(movement).to be_pendente
      expect(movement.occurred_at.to_date).to eq(due)
      expect(account.reload.current_balance).to eq(1000)
      expect(tomato.reload.quantity).to eq(10)

      movement.pay!
      expect(account.reload.current_balance).to eq(950)
    end
  end

  it "records the last price paid to the supplier" do
    create(:product_supplier, product: tomato, supplier: supplier, last_price: 3)
    register
    expect(tomato.product_suppliers.find_by!(supplier: supplier).last_price).to eq(4)
    expect(onion.suppliers).to include(supplier)
  end

  it "saves nothing when the entry is invalid" do
    ok, entry = register(payment_method: "boleto", due_on: nil)
    expect(ok).to be false
    expect(entry.errors[:due_on]).to be_present
    expect(StockEntry.count).to eq(0)
    expect(Movement.count).to eq(0)
    expect(tomato.reload.quantity).to eq(0)
  end

  it "rolls everything back when the stock cannot be updated" do
    allow_any_instance_of(StockMovement).to receive(:apply_to_product!).and_raise(ActiveRecord::RecordInvalid.new(StockMovement.new))
    ok, = register
    expect(ok).to be false
    expect(StockEntry.count).to eq(0)
    expect(Movement.count).to eq(0)
    expect(account.reload.current_balance).to eq(1000)
  end
end
