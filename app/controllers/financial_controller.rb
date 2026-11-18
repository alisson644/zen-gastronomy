class FinancialController < ApplicationController
  requires_permission "financial.view"
  before_action :require_company!

  def index
    @company = current_company
    @accounts = @company.accounts.order(:name)
    @categories = @company.categories.includes(:subcategories).order(:id)
    @movements = @company.movements.includes(:account, :related_account, :category, :subcategory).order(occurred_at: :desc, created_at: :desc)
    @account = Account.new
    @movement = Movement.new(occurred_at: Date.current)
  end
end
