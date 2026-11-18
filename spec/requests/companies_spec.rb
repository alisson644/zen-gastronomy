require 'rails_helper'

RSpec.describe "Companies", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user, company: nil) }

  before { sign_in user }

  describe "POST /companies" do
    it "creates the company, links it to the current user and redirects to the dashboard" do
      expect {
        post companies_path, params: { name: "Restaurante Zen", cnpj: "12.345.678/0001-99", address: "Rua A, 1" }
      }.to change(Company, :count).by(1)

      company = Company.last
      expect(company.name).to eq("Restaurante Zen")
      expect(user.reload.company).to eq(company)
      expect(user.role).to eq(company.roles.find_by!(key: "dono"))
      expect(response).to redirect_to(root_path)
    end

    it "seeds the default chart of accounts for the new company" do
      post companies_path, params: { name: "Restaurante Zen" }

      company = user.reload.company
      expect(company.categories.count).to eq(12)
      expect(company.accounts.pluck(:name)).to include("Caixa Dinheiro")
    end

    it "does not create a company without a name" do
      expect {
        post companies_path, params: { name: "" }
      }.not_to change(Company, :count)

      expect(user.reload.company).to be_nil
    end
  end

  it "shows the create-company modal while the user has no company" do
    get root_path
    expect(response.body).to include("Para começar vamos cadastrar a sua empresa")
  end
end
