class AccountsController < ApplicationController
  requires_permission "accounts.manage"
  before_action :require_company!
  before_action :set_company, only: [ :create ]

  def create
    @account = @company.accounts.new(account_params)
    @account.initial_balance ||= 0
    @account.current_balance = @account.initial_balance

    if @account.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to financial_index_path, notice: "Conta criada com sucesso." }
      end
    else
      render turbo_stream: turbo_stream.replace("account_form", partial: "partials/account_form", locals: { account: @account }),
             status: :unprocessable_content
    end
  end

  private

  def set_company
    @company = current_company
  end

  def account_params
    params.require(:account).permit(:name, :account_type, :initial_balance)
  end
end
