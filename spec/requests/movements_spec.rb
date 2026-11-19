require 'rails_helper'

RSpec.describe "Movements", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }
  let!(:bank) { company.accounts.create!(name: "Banco", account_type: :banco, initial_balance: 100, current_balance: 100) }
  let!(:cash) { company.accounts.find_by!(name: "Caixa Dinheiro") }
  let(:subcategory) { company.subcategories.first }

  before { sign_in user }

  def create_movement(attrs = {})
    post movements_path, params: {
      movement: { mv_type: "entrada", amount: "50", occurred_at: Date.current.to_s,
                  account_id: bank.id, subcategory_id: subcategory.id }.merge(attrs)
    }, as: :turbo_stream
  end

  it "creates an income, increases the balance and streams chart and table" do
    expect { create_movement }.to change { company.movements.count }.by(1)

    movement = company.movements.last
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('target="financial_summary"', 'target="movements_table"', dom_id(movement))
    expect(response.body).to include(subcategory.name, subcategory.category.name)
    expect(movement.category_id).to eq(subcategory.category_id)
    expect(movement.creator).to eq(user)
    expect(bank.reload.current_balance).to eq(150)
  end

  it "decreases the balance on expense" do
    create_movement(mv_type: "saida", amount: "30")
    expect(bank.reload.current_balance).to eq(70)
  end

  it "moves money between accounts on transfer" do
    create_movement(mv_type: "transfer", amount: "40", related_account_id: cash.id)
    expect(bank.reload.current_balance).to eq(60)
    expect(cash.reload.current_balance).to eq(40)
  end

  it "accepts amount with comma as decimal separator (1.234,56)" do
    bank.update!(current_balance: 0)
    create_movement(amount: "1.234,56")
    expect(response).to have_http_status(:ok)
    expect(company.movements.last.amount).to eq(BigDecimal("1234.56"))
    expect(bank.reload.current_balance).to eq(BigDecimal("1234.56"))
  end

  it "re-renders the amount with comma when the form is invalid" do
    create_movement(amount: "12,5", account_id: nil)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('value="12,50"')
  end

  it "rejects a transfer without destination account" do
    expect { create_movement(mv_type: "transfer") }.not_to change(Movement, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('target="transaction_form"')
  end

  it "rejects an account from another company" do
    other = create(:company, name: "Outra").accounts.first
    expect { create_movement(account_id: other.id) }.not_to change(Movement, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects a transfer to an account from another company" do
    other = create(:company, name: "Outra").accounts.first
    expect { create_movement(mv_type: "transfer", amount: "40", related_account_id: other.id) }.not_to change(Movement, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(other.reload.current_balance).to eq(0)
    expect(bank.reload.current_balance).to eq(100)
  end

  it "rejects invalid amount" do
    create_movement(amount: "0")
    expect(response).to have_http_status(:unprocessable_content)
  end

  private

  def dom_id(record)
    ActionView::RecordIdentifier.dom_id(record)
  end
end
