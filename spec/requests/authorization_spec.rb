require "rails_helper"

RSpec.describe "Authorization by role", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:company) { create(:company) }
  let(:bank) { company.accounts.find_by!(name: "Caixa Dinheiro") }
  let(:subcategory) { company.subcategories.first }

  def post_movement
    post movements_path, params: { movement: { mv_type: "entrada", amount: "10", occurred_at: Date.current.to_s,
                                               account_id: bank.id, subcategory_id: subcategory.id } }, as: :turbo_stream
  end

  def post_account
    post accounts_path, params: { account: { name: "Banco Novo", account_type: "banco", initial_balance: "0" } }, as: :turbo_stream
  end

  def post_category
    post categories_path, params: { category: { name: "Nova", is_income: "false" } }, as: :turbo_stream
  end

  def post_subcategory
    post subcategories_path, params: { subcategory: { name: "Nova sub", category_id: subcategory.category_id } }, as: :turbo_stream
  end

  context "when logged out" do
    it "keeps the landing page public" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects the financial page to the login" do
      get financial_index_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not let anonymous users create movements" do
      expect { post movements_path, params: { movement: { amount: "1" } } }.not_to change(Movement, :count)
    end
  end

  context "as dono" do
    let(:user) { create(:user, :dono, company: company) }

    before { sign_in user }

    it "sees the dashboard and the financial page" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dashboard")
      get financial_index_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nova conta", "Nova transação")
    end

    it "creates movements, accounts, categories and subcategories" do
      expect { post_movement }.to change(Movement, :count).by(1)
      expect { post_account }.to change(Account, :count).by(1)
      expect { post_category }.to change(Category, :count).by(1)
      expect { post_subcategory }.to change(Subcategory, :count).by(1)
    end

    it "sees Equipe and Perfis but not the admin pages in the sidebar" do
      get financial_index_path
      expect(response.body).to include(%(href="#{team_members_path}"), %(href="#{roles_path}"))
      expect(response.body).not_to include(admin_companies_path)
    end

    it "cannot open admin pages" do
      get admin_companies_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Você não tem permissão")
    end
  end

  context "as administrativo" do
    let(:user) { create(:user, :administrativo, company: company) }

    before { sign_in user }

    it "is sent from the dashboard to the financial page" do
      get root_path
      expect(response).to redirect_to(financial_index_path)
    end

    it "lands on the financial page after login" do
      sign_out user
      post user_session_path, params: { user: { email: user.email, password: "hash_senha" } }
      expect(response).to redirect_to(financial_index_path)
    end

    it "sees the financial page with only the new-transaction action" do
      get financial_index_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nova transação")
      expect(response.body).not_to include("Nova conta", 'commandfor="category"', 'commandfor="subcategory"')
    end

    it "only sees Financeiro in the sidebar" do
      get financial_index_path
      expect(response.body).to include(financial_index_path)
      expect(response.body).not_to include(%(href="#{team_members_path}"), %(href="#{admin_companies_path}"), %(title="Dashboard"))
    end

    it "creates movements" do
      expect { post_movement }.to change(Movement, :count).by(1)
      expect(response).to have_http_status(:ok)
    end

    it "is forbidden to create accounts, categories and subcategories" do
      expect { post_account }.not_to change(Account, :count)
      expect(response).to have_http_status(:forbidden)
      expect { post_category }.not_to change(Category, :count)
      expect(response).to have_http_status(:forbidden)
      expect { post_subcategory }.not_to change(Subcategory, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "cannot open the team and roles pages" do
      get team_members_path
      expect(response).to redirect_to(financial_index_path)
      get roles_path
      expect(response).to redirect_to(financial_index_path)
    end
  end

  context "as system admin" do
    let(:admin) { create(:user, :admin) }
    let!(:other_company) { create(:company, name: "Outra Empresa") }

    before do
      company.update!(name: "Empresa Alvo")
      sign_in admin
    end

    it "does not see the create-company modal and lands on the companies list" do
      get root_path
      expect(response).to redirect_to(admin_companies_path)
      follow_redirect!
      expect(response.body).not_to include("Para começar vamos cadastrar a sua empresa")
      expect(response.body).to include("Empresa Alvo", "Outra Empresa")
    end

    it "views a company's dashboard and financial page, then stops viewing" do
      sub = company.subcategories.find_by!(name: "Aluguel")
      company.movements.create!(mv_type: :saida, amount: 987.65, occurred_at: Date.current, account: bank,
                                subcategory: sub, category: sub.category, creator: create(:user, company: company))

      post admin_company_view_path, params: { company_id: company.id }
      expect(response).to redirect_to(root_path)

      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Visualizando", "Empresa Alvo", "R$ 987,65")

      get financial_index_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Caixa Dinheiro")

      delete admin_company_view_path
      expect(response).to redirect_to(admin_companies_path)
      get root_path
      expect(response).to redirect_to(admin_companies_path)
    end

    it "creates movements in the company being viewed" do
      post admin_company_view_path, params: { company_id: company.id }
      expect { post_movement }.to change { company.movements.count }.by(1)
    end
  end
end
