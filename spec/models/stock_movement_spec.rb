require "rails_helper"

RSpec.describe StockMovement, type: :model do
  let(:user) { create(:user) }
  let(:company) { user.company }
  let(:product) { create(:product, company: company) }

  def move(kind, quantity, unit_cost: nil, **attrs)
    company.stock_movements.create!(product: product, kind: kind, quantity: quantity, unit_cost: unit_cost, creator: user, **attrs)
  end

  it { should belong_to(:company) }
  it { should belong_to(:product) }
  it { should belong_to(:creator).class_name("User").without_validating_presence }
  it { should validate_presence_of(:creator).on(:create) }
  it { should belong_to(:source).optional }
  it { should define_enum_for(:kind).with_values(entrada: 0, saida: 1, ajuste: 2) }

  it "increases the quantity and sets the average cost on entrada" do
    move(:entrada, 10, unit_cost: 4)
    move(:entrada, 10, unit_cost: 6)
    product.reload
    expect(product.quantity).to eq(20)
    expect(product.average_cost).to eq(5)
  end

  it "stores saida as a negative quantity and lowers the stock" do
    move(:entrada, 10, unit_cost: 4)
    output = move(:saida, "2,5", reason: "consumo")
    expect(output.quantity).to eq(-2.5)
    expect(product.reload.quantity).to eq(7.5)
    expect(product.average_cost).to eq(4)
  end

  it "does not let a saida leave the stock negative" do
    move(:entrada, 1, unit_cost: 4)
    output = company.stock_movements.new(product: product, kind: :saida, quantity: 2, creator: user, reason: "perda")
    expect(output).not_to be_valid
    expect(output.errors[:quantity]).to be_present
  end

  it "requires a known reason for saida" do
    move(:entrada, 5, unit_cost: 1)
    expect(company.stock_movements.new(product: product, kind: :saida, quantity: 1, creator: user, reason: "x")).not_to be_valid
  end

  it "applies signed adjustments" do
    move(:entrada, 10, unit_cost: 4)
    move(:ajuste, -3)
    expect(product.reload.quantity).to eq(7)
  end

  it "requires a positive quantity and a unit cost on entrada" do
    expect(company.stock_movements.new(product: product, kind: :entrada, quantity: 0, unit_cost: 1, creator: user)).not_to be_valid
    expect(company.stock_movements.new(product: product, kind: :entrada, quantity: 1, creator: user)).not_to be_valid
  end

  it "uses the entry cost when the stock was empty or negative" do
    product.update_column(:quantity, 0)
    move(:entrada, 2, unit_cost: 9)
    expect(product.reload.average_cost).to eq(9)
  end

  it "rejects a product from another company" do
    foreign = create(:product)
    movement = company.stock_movements.new(product: foreign, kind: :entrada, quantity: 1, unit_cost: 1, creator: user)
    expect(movement).not_to be_valid
  end
end
