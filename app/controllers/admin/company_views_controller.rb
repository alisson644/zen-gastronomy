module Admin
  # O admin do sistema "entra" numa empresa para navegar no Dashboard e no Financeiro dela.
  class CompanyViewsController < ApplicationController
    requires_permission "companies.view_all"

    def create
      company = Company.find(params[:company_id])
      session[:viewing_company_id] = company.id
      redirect_to root_path, notice: "Visualizando #{company.name}.", status: :see_other
    end

    def destroy
      session.delete(:viewing_company_id)
      redirect_to admin_companies_path, status: :see_other
    end
  end
end
