require 'rails_helper'

RSpec.describe "Financials", type: :request do
  include Devise::Test::IntegrationHelpers

  describe "GET /index" do
    it "returns http success with chart, table and modals" do
      sign_in create(:user)
      get "/financial/index"
      expect(response).to have_http_status(:success)
      expect(response.body).to include('id="financial_summary"', 'id="movements_table"', 'id="account_form"', 'id="transaction_form"', 'data-controller="chartjs"', 'id="subcategory_select"', 'commandfor="category"', 'commandfor="subcategory"', 'id="category_form"', 'id="subcategory_form"')
    end
  end
end
