require "rails_helper"

# Nenhuma página deve ter links que não levam a lugar nenhum (href="#").
RSpec.describe "Dead links", type: :request do
  include Devise::Test::IntegrationHelpers

  it "landing page has no placeholder links" do
    get root_path
    expect(response.body).not_to include('href="#"')
  end

  context "when logged in" do
    let(:user) { create(:user) }

    before { sign_in user }

    [ :root_path, :financial_index_path, :edit_user_registration_path, :stock_path, :products_path,
      :suppliers_path, :stock_entries_path, :stock_counts_path, :new_product_path, :new_stock_entry_path ].each do |page|
      it "#{page} has no placeholder links in the sidebar" do
        get send(page)
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('href="#"')
        expect(response.body).not_to include("Projects", "Calendar", "Reports", "Settings")
      end
    end
  end
end
