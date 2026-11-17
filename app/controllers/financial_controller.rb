class FinancialController < ApplicationController
  def index
    @company = current_user.company
    @accounts = @company.accounts.order(:name)
    @categories = @company.categories.includes(:subcategories).order(:id)
    @movements = @company.movements.includes(:account, :related_account, :category, :subcategory).order(occurred_at: :desc, created_at: :desc)
    @account = Account.new
    @movement = Movement.new(occurred_at: Date.current)
  end
end
