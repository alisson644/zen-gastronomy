require 'rails_helper'

RSpec.describe "Home", type: :request do
  include Devise::Test::IntegrationHelpers

  it "renders the landing page when logged out" do
    get root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Criar conta")
  end

  context "when logged in" do
    let(:user) { create(:user) }
    let(:company) { user.company }

    before { sign_in user }

    it "shows empty states without movements" do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Gasto no mês", "Nenhuma despesa neste mês.", "Nenhuma entrada ou despesa nos últimos 6 meses.")
    end

    it "renders the charts for the selected month" do
      sub = company.subcategories.find_by!(name: "Aluguel")
      company.movements.create!(mv_type: :saida, amount: 1234.5, occurred_at: Date.new(2026, 3, 10), account: company.accounts.first,
                                subcategory: sub, category: sub.category, creator: user)

      get root_path(month: "2026-03")
      expect(response.body).to include("Março de 2026", "R$ 1.234,50", 'data-controller="money-chart"', "Custo com Ocupação")
      expect(response.body).to include("month=2026-02", "month=2026-04")
    end
  end
end
