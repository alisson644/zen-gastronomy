class MovementsController < ApplicationController
  requires_permission "movements.create"
  before_action :require_company!
  before_action :set_company

  def create
    @movement = @company.movements.new(movement_params)
    @movement.creator = current_user
    @movement.category_id = @company.subcategories.find_by(id: @movement.subcategory_id)&.category_id
    @movement.account = find_account(:account_id)
    @movement.related_account = @movement.transfer? ? find_account(:related_account_id) : nil

    if @movement.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to financial_index_path, notice: "Transação criada com sucesso." }
      end
    else
      render turbo_stream: turbo_stream.replace("transaction_form", partial: "partials/transaction_form",
                                                locals: { movement: @movement, accounts: accounts, categories: categories }),
             status: :unprocessable_content
    end
  end

  private

  def set_company
    @company = current_company
  end

  def accounts
    @company.accounts.order(:name)
  end

  def categories
    @company.categories.includes(:subcategories).order(:id)
  end
  helper_method :accounts, :categories

  def movement_params
    params.require(:movement).permit(:mv_type, :amount, :occurred_at, :description, :subcategory_id)
  end

  # Account IDs are resolved through the company so a movement can never point to another tenant's account.
  def find_account(key)
    @company.accounts.find_by(id: params.dig(:movement, key))
  end
end
