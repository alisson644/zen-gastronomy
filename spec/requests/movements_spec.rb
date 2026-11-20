require 'rails_helper'

RSpec.describe "Movements", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }
  let!(:bank) { company.accounts.create!(name: "Banco", account_type: :banco, initial_balance: 100, current_balance: 100) }
  let!(:cash) { company.accounts.find_by!(name: "Caixa Dinheiro") }
  let(:subcategory) { company.subcategories.find_by!(name: "Pix") }
  let(:expense_subcategory) { company.subcategories.find_by!(name: "Aluguel") }

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
    create_movement(mv_type: "saida", amount: "30", subcategory_id: expense_subcategory.id)
    expect(bank.reload.current_balance).to eq(70)
  end

  it "rejects an expense with an income category" do
    expect { create_movement(mv_type: "saida", amount: "30") }.not_to change(Movement, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects an income with an expense category" do
    expect { create_movement(subcategory_id: expense_subcategory.id) }.not_to change(Movement, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "moves money between accounts on transfer" do
    create_movement(mv_type: "transfer", amount: "40", related_account_id: cash.id)
    expect(bank.reload.current_balance).to eq(60)
    expect(cash.reload.current_balance).to eq(40)
  end

  it "creates a transfer without category, ignoring any submitted subcategory" do
    expect {
      create_movement(mv_type: "transfer", amount: "40", related_account_id: cash.id, subcategory_id: nil)
    }.to change(Movement, :count).by(1)
    expect(response).to have_http_status(:ok)

    create_movement(mv_type: "transfer", amount: "10", related_account_id: cash.id)
    movement = company.movements.last
    expect(movement.category).to be_nil
    expect(movement.subcategory).to be_nil
  end

  it "ignores the destination account for non-transfer movements" do
    create_movement(related_account_id: cash.id)
    expect(company.movements.last.related_account).to be_nil
    expect(cash.reload.current_balance).to eq(0)
  end

  it "renders the transaction form wired to toggle categories by type" do
    get financial_index_path
    expect(response.body).to include('data-transaction-type-target="relatedAccount"', 'data-transaction-type-target="category"')
    expect(response.body).to match(/<optgroup[^>]*data-income="true"[^>]*label="Entrada de caixa"/)
    expect(response.body).to match(/<optgroup[^>]*data-income="false"[^>]*label="Custo com Ocupação"/)
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

  describe "paying a pending movement" do
    let!(:pending) do
      company.movements.create!(mv_type: :saida, amount: 40, occurred_at: Date.current + 5, account: bank, status: :pendente,
                                subcategory: expense_subcategory, category: expense_subcategory.category, creator: user)
    end

    it "shows the pending badge and the pay button" do
      get financial_index_path
      expect(response.body).to include("Pendente", pay_movement_path(pending))
    end

    it "marks it as paid, debits the account and refreshes the page" do
      patch pay_movement_path(pending), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="financial_summary"', 'target="movements_table"')
      expect(pending.reload).to be_pago
      expect(bank.reload.current_balance).to eq(60)
    end

    it "does not debit twice" do
      patch pay_movement_path(pending), as: :turbo_stream
      patch pay_movement_path(pending), as: :turbo_stream
      expect(bank.reload.current_balance).to eq(60)
    end

    it "redirects on html requests" do
      patch pay_movement_path(pending)
      expect(response).to redirect_to(financial_index_path)
    end

    it "cannot pay another company's movement" do
      other_user = create(:user)
      other_account = other_user.company.accounts.first
      sub = other_user.company.subcategories.find_by!(name: "Aluguel")
      foreign = other_user.company.movements.create!(mv_type: :saida, amount: 1, occurred_at: Date.current, account: other_account,
                                                     status: :pendente, subcategory: sub, category: sub.category, creator: other_user)
      patch pay_movement_path(foreign), as: :turbo_stream
      expect(response).to have_http_status(:not_found)
      expect(foreign.reload).to be_pendente
    end
  end
end
