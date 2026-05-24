class AccountsController < ApplicationController
  before_action :set_company, only: [ :create ]
  def create
    @account = @company.accounts.new(account_params)
    if @account.save
      redirect_to root_path, status: :created
    else
      render json: @account.errors, status: :unprocessable_entity
    end
  end

  private
  def set_company
    @company = Company.find(current_user.company.id)
  end
  def account_params
    params.require(:account).permit(:name, :account_type, :current_balance, :initial_balance)
  end
end
