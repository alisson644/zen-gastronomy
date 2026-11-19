require 'rails_helper'

RSpec.describe "Home", type: :request do
  include Devise::Test::IntegrationHelpers

  it "renders the landing page when logged out" do
    get root_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Criar conta")
  end

  describe "landing page" do
    before { get root_path }

    it "shows the sales sections" do
      expect(response.body).to include('id="recursos"', 'id="como-funciona"', 'id="planos"', 'id="duvidas"')
      expect(response.body).to include("Pare de adivinhar.")
    end

    it "shows mockups of the system" do
      expect(response.body).to include("Entradas no mês", "Lançamentos em segundos", "Sua equipe, suas regras")
    end

    it "shows the plans with monthly and yearly prices" do
      expect(response.body).to include("Essencial", "Profissional", "Rede", "Mais escolhido")
      expect(response.body).to include("R$ 79", "R$ 149", "R$ 299", "R$ 66", "R$ 124", "R$ 249")
      expect(response.body).to include('data-controller="pricing-toggle"')
    end

    it "links the calls to action to sign up and sign in" do
      expect(response.body.scan(%(href="#{new_user_registration_path}")).size).to be >= 5
      expect(response.body).to include(%(href="#{new_user_session_path}"))
    end
  end

  context "when logged in" do
    let(:user) { create(:user) }
    let(:company) { user.company }

    before { sign_in user }

    it "shows empty states without movements" do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("Pare de adivinhar.", 'id="planos"')
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
