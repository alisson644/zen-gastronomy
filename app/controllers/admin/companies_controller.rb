module Admin
  class CompaniesController < ApplicationController
    requires_permission "companies.view_all"

    def index
      @companies = Company.left_joins(:users).select("companies.*, COUNT(users.id) AS users_count").group("companies.id").order(:name)
    end
  end
end
