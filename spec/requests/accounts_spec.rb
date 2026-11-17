require 'rails_helper'

RSpec.describe "Accounts", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }

  before { sign_in user }

  describe "POST /accounts" do
    it "creates the account with current balance equal to initial balance and streams the updates" do
      expect {
        post accounts_path, params: { account: { name: "Banco X", account_type: "banco", initial_balance: "150.50" } }, as: :turbo_stream
      }.to change { company.accounts.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="financial_summary"', 'target="transaction_form"', "Banco X")
      expect(company.accounts.find_by(name: "Banco X").current_balance).to eq(150.50)
    end

    it "accepts initial balance with comma" do
      post accounts_path, params: { account: { name: "Cofre", account_type: "caixa", initial_balance: "2.500,75" } }, as: :turbo_stream
      account = company.accounts.find_by!(name: "Cofre")
      expect(account.initial_balance).to eq(BigDecimal("2500.75"))
      expect(account.current_balance).to eq(BigDecimal("2500.75"))
    end

    it "re-renders the form with errors when invalid" do
      post accounts_path, params: { account: { name: "", account_type: "banco" } }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('target="account_form"')
    end
  end
end
