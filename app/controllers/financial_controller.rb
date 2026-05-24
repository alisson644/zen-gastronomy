class FinancialController < ApplicationController
  def index
    @company = current_user.company
    @accounts_name = @company.accounts
    @account = Account.new
    @movement = Movement.new
  end
end
