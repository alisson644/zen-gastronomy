require "rails_helper"

RSpec.describe "Company roles", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:owner) { create(:user) }
  let(:company) { owner.company }
  let(:administrativo_role) { company.roles.find_by!(key: "administrativo") }

  context "as dono" do
    before { sign_in owner }

    it "lists only the company's roles" do
      create(:role, company: create(:company), name: "Perfil de outra empresa")
      Role.admin!

      get roles_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dono", "Administrativo")
      expect(response.body).not_to include("Perfil de outra empresa", "Administrador do sistema")
    end

    it "shows only company permissions in the form" do
      get edit_role_path(administrativo_role)
      Permission::COMPANY.each { |key| expect(response.body).to include(Permission.label(key)) }
      expect(response.body).not_to include(Permission.label("companies.view_all"))
    end

    it "changes what the administrativo can see" do
      worker = create(:user, :administrativo, company: company)

      patch role_path(administrativo_role), params: { role: { name: "Administrativo", permissions: [ "", "financial.view", "movements.create", "dashboard.view" ] } }
      expect(response).to redirect_to(roles_path)

      sign_out owner
      sign_in worker.reload
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Gasto no mês")
    end

    it "does not affect other companies' administrativo" do
      other_role = create(:company).roles.find_by!(key: "administrativo")
      patch role_path(administrativo_role), params: { role: { name: "Administrativo", permissions: [ "", "dashboard.view" ] } }
      expect(other_role.reload.permissions).not_to include("dashboard.view")
    end

    it "creates a new role for the company" do
      expect {
        post roles_path, params: { role: { name: "Caixa", permissions: [ "", "financial.view", "movements.create" ] } }
      }.to change { company.roles.count }.by(1)

      expect(company.roles.find_by!(name: "Caixa").permissions).to match_array(%w[financial.view movements.create])
    end

    it "cannot grant global permissions" do
      post roles_path, params: { role: { name: "Espião", permissions: [ "", "companies.view_all" ] } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(company.roles.find_by(name: "Espião")).to be_nil
    end

    it "keeps the Dono with every permission" do
      dono = company.roles.find_by!(key: "dono")
      patch role_path(dono), params: { role: { name: "Dono", permissions: [ "" ] } }
      expect(owner.reload.can?("team.manage")).to be true
      expect(owner.can?("roles.manage")).to be true
    end

    it "cannot edit or delete roles of another company" do
      foreign = create(:role, company: create(:company))
      get edit_role_path(foreign)
      expect(response).to have_http_status(:not_found)

      sign_in owner
      expect { delete role_path(foreign) }.not_to change(Role, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "cannot touch the system admin role" do
      patch role_path(Role.admin!), params: { role: { name: "X", permissions: [ "" ] } }
      expect(response).to have_http_status(:not_found)
    end

    it "deletes custom roles but not the default ones" do
      custom = create(:role, company: company)
      expect { delete role_path(custom) }.to change(Role, :count).by(-1)
      expect { delete role_path(administrativo_role) }.not_to change(Role, :count)
      expect(response).to redirect_to(roles_path)
    end
  end

  context "as system admin viewing the company" do
    it "edits the company's roles" do
      sign_in create(:user, :admin)
      post admin_company_view_path, params: { company_id: company.id }

      patch role_path(administrativo_role), params: { role: { name: "Administrativo", permissions: [ "", "financial.view" ] } }
      expect(administrativo_role.reload.permissions).to eq(%w[financial.view])
    end
  end

  context "as administrativo" do
    it "is denied" do
      sign_in create(:user, :administrativo, company: company)
      expect { post roles_path, params: { role: { name: "X", permissions: [ "financial.view" ] } } }.not_to change(Role, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
