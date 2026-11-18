require "rails_helper"

RSpec.describe "Team members", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:owner) { create(:user, :dono) }
  let(:company) { owner.company }

  def create_member(attrs = {})
    post team_members_path, params: {
      user: { username: "Ana", email: "ana@example.com", password: "senha123", password_confirmation: "senha123",
              role_id: company.roles.find_by!(key: "administrativo").id }.merge(attrs)
    }
  end

  context "as dono" do
    before { sign_in owner }

    it "lists the company members" do
      colleague = create(:user, :administrativo, company: company, username: "Carla")
      outsider = create(:user, username: "Estranho")

      get team_members_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(owner.email, colleague.email, "Administrativo")
      expect(response.body).not_to include(outsider.email)
    end

    it "shows the new-member form with the company's roles only" do
      create(:role, company: company, name: "Caixa")
      create(:role, company: create(:company), name: "Gerente de outra empresa")
      Role.admin!

      get new_team_member_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Administrativo", "Dono", "Caixa")
      expect(response.body).not_to include("Administrador do sistema", "Gerente de outra empresa")
    end

    it "creates a member with a custom role of the company" do
      caixa = create(:role, company: company, name: "Caixa", permissions: %w[financial.view movements.create])
      create_member(role_id: caixa.id)
      expect(company.users.find_by!(email: "ana@example.com").role).to eq(caixa)
    end

    it "cannot assign a role of another company" do
      foreign = create(:company).roles.find_by!(key: "administrativo")
      expect { create_member(role_id: foreign.id) }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "creates an administrativo in the owner's company" do
      expect { create_member }.to change { company.users.count }.by(1)

      member = company.users.find_by!(email: "ana@example.com")
      expect(member.role.key).to eq("administrativo")
      expect(response).to redirect_to(team_members_path)
    end

    it "creates as many administrativos as needed" do
      5.times { |i| create_member(email: "membro#{i}@example.com") }
      expect(company.users.joins(:role).where(roles: { key: "administrativo" }).count).to eq(5)
    end

    it "lets the new member log in" do
      create_member
      sign_out owner
      post user_session_path, params: { user: { email: "ana@example.com", password: "senha123" } }
      expect(response).to redirect_to(financial_index_path)
    end

    it "cannot assign the system admin role" do
      expect { create_member(role_id: Role.admin!.id) }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form on invalid data" do
      expect { create_member(email: "") }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("bg-red-50")
    end

    it "removes a member of the company" do
      member = create(:user, :administrativo, company: company)
      expect { delete team_member_path(member) }.to change(User, :count).by(-1)
      expect(response).to redirect_to(team_members_path)
    end

    it "cannot remove itself" do
      expect { delete team_member_path(owner) }.not_to change(User, :count)
      expect(response).to redirect_to(team_members_path)
    end

    it "cannot remove members of other companies" do
      outsider = create(:user)
      expect { delete team_member_path(outsider) }.not_to change(User, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  context "as administrativo" do
    it "cannot create members" do
      sign_in create(:user, :administrativo, company: company)
      expect { create_member(email: "x@example.com") }.not_to change(User, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
