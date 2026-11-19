require "rails_helper"

RSpec.describe "Users::Registrations (sign up)", type: :request do
  def sign_up_params(user: {}, company: {})
    {
      user: {
        username: "Maria",
        email: "maria@restaurante.com",
        password: "segredo123",
        password_confirmation: "segredo123",
        company_attributes: { name: "Restaurante Zen", cnpj: "12.345.678/0001-99", address: "Rua A, 1" }.merge(company)
      }.merge(user)
    }
  end

  describe "GET /users/sign_up" do
    it "shows the account and company steps" do
      get new_user_registration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sua conta", "Sua empresa", 'data-controller="registration-steps"')
      expect(response.body).to include('name="user[company_attributes][name]"', 'name="user[avatar]"')
    end
  end

  describe "POST /users" do
    it "creates the user with a new company as its owner and signs in" do
      expect {
        post user_registration_path, params: sign_up_params
      }.to change(User, :count).by(1).and change(Company, :count).by(1)

      user = User.find_by!(email: "maria@restaurante.com")
      company = user.company
      expect(company.name).to eq("Restaurante Zen")
      expect(company.cnpj).to eq("12.345.678/0001-99")
      expect(company.address).to eq("Rua A, 1")
      expect(user.role).to eq(company.roles.find_by!(key: "dono"))
      expect(response).to redirect_to(root_path)

      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Para começar vamos cadastrar a sua empresa")
    end

    it "seeds the default chart of accounts for the new company" do
      post user_registration_path, params: sign_up_params

      company = User.find_by!(email: "maria@restaurante.com").company
      expect(company.categories.count).to eq(12)
      expect(company.categories.find_by!(name: "Entrada de caixa")).to be_is_income
      expect(company.subcategories.count).to be > 60
      expect(company.accounts.pluck(:name)).to include("Caixa Dinheiro")
    end

    it "attaches the profile photo when one is chosen" do
      post user_registration_path, params: sign_up_params(user: { avatar: fixture_file_upload("avatar.png", "image/png") })

      expect(User.find_by!(email: "maria@restaurante.com").avatar).to be_attached
    end

    it "does not create anything with an invalid photo" do
      expect {
        post user_registration_path, params: sign_up_params(user: { avatar: fixture_file_upload("avatar.txt", "text/plain") })
      }.not_to change { [ User.count, Company.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("deve ser PNG, JPG ou WEBP")
    end

    it "does not create anything without a company name" do
      expect {
        post user_registration_path, params: sign_up_params(company: { name: "" })
      }.not_to change { [ User.count, Company.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nome da empresa can&#39;t be blank")
    end

    it "does not create the company when the account data is invalid" do
      expect {
        post user_registration_path, params: sign_up_params(user: { password_confirmation: "outra" })
      }.not_to change { [ User.count, Company.count ] }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Password confirmation doesn&#39;t match")
    end

    it "does not create the company when the e-mail is already taken" do
      create(:user, email: "maria@restaurante.com")

      expect {
        post user_registration_path, params: sign_up_params
      }.not_to change(Company, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
