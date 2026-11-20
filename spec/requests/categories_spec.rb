require 'rails_helper'

RSpec.describe "Categories and subcategories", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:company) { user.company }

  before { sign_in user }

  describe "POST /categories" do
    it "creates a category with its first subcategory and preselects it in the transaction form" do
      expect {
        post categories_path, params: { category: { name: "Delivery", is_income: "false", subcategory_name: "iFood" } }, as: :turbo_stream
      }.to change { company.categories.count }.by(1).and change { company.subcategories.count }.by(1)

      subcategory = company.subcategories.find_by!(name: "iFood")
      expect(subcategory.category.name).to eq("Delivery")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="subcategory_select"', 'target="category_form"', 'target="subcategory_form"')
      expect(response.body).to match(/<option selected="selected" value="#{subcategory.id}">iFood/)
    end

    it "creates a category without subcategory" do
      expect {
        post categories_path, params: { category: { name: "Eventos", is_income: "true" } }, as: :turbo_stream
      }.to change { company.categories.count }.by(1).and change { company.subcategories.count }.by(0)
      expect(company.categories.find_by!(name: "Eventos").is_income).to be(true)
    end

    it "re-renders the form when invalid and creates nothing" do
      expect {
        post categories_path, params: { category: { name: "", subcategory_name: "X" } }, as: :turbo_stream
      }.not_to change(Subcategory, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('target="category_form"')
    end
  end

  describe "POST /subcategories" do
    let(:category) { company.categories.first }

    it "creates a subcategory and preselects it" do
      post subcategories_path, params: { subcategory: { name: "Embalagens", category_id: category.id } }, as: :turbo_stream

      subcategory = company.subcategories.find_by!(name: "Embalagens")
      expect(subcategory.category).to eq(category)
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<option selected="selected" value="#{subcategory.id}">Embalagens/)
    end

    it "rejects a category from another company" do
      other_category = create(:company, name: "Outra").categories.first
      expect {
        post subcategories_path, params: { subcategory: { name: "Hack", category_id: other_category.id } }, as: :turbo_stream
      }.not_to change(Subcategory, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('target="subcategory_form"')
    end
  end

  describe "from the stock forms (expense only)" do
    it "creates an expense category even if income is submitted and preselects its subcategory in the stock selects" do
      post categories_path, params: { expense_only: "1", category: { name: "Embalagens", is_income: "true", subcategory_name: "Caixas" } }, as: :turbo_stream

      category = company.categories.find_by!(name: "Embalagens")
      subcategory = category.subcategories.find_by!(name: "Caixas")
      expect(category.is_income).to be(false)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="product_subcategory_select"', 'target="stock_entry_subcategory_select"',
                                       'name="product[subcategory_id]"', 'name="stock_entry[subcategory_id]"')
      expect(response.body).to match(/<option selected="selected" value="#{subcategory.id}">Caixas/)
      expect(response.body).not_to include("Entrada (receita)")
    end

    it "does not reset the stock selects when the category has no subcategory" do
      post categories_path, params: { expense_only: "1", category: { name: "Sem sub" } }, as: :turbo_stream
      expect(response.body).not_to include('target="product_subcategory_select"')
    end

    it "keeps the form expense-only when invalid" do
      post categories_path, params: { expense_only: "1", category: { name: "" } }, as: :turbo_stream
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('name="expense_only"')
      expect(response.body).not_to include("Entrada (receita)")
    end

    it "creates a subcategory, offers only expense categories and preselects it" do
      category = company.categories.find_by!(name: "Despesas Variáveis - CMV")
      post subcategories_path, params: { expense_only: "1", subcategory: { name: "Descartáveis", category_id: category.id } }, as: :turbo_stream

      subcategory = company.subcategories.find_by!(name: "Descartáveis")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('target="product_subcategory_select"', 'target="stock_entry_subcategory_select"')
      expect(response.body).to match(/<option selected="selected" value="#{subcategory.id}">Descartáveis/)
      expect(response.body).not_to include(">Entrada de caixa</option>")
    end

    it "rejects an income category for the subcategory" do
      income = company.categories.find_by!(is_income: true)
      expect {
        post subcategories_path, params: { expense_only: "1", subcategory: { name: "X", category_id: income.id } }, as: :turbo_stream
      }.not_to change(Subcategory, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
