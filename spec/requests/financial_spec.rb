require 'rails_helper'

RSpec.describe "Financials", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/financial/index"
      expect(response).to have_http_status(:success)
    end
  end

end
