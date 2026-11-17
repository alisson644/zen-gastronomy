class MovementsController < ApplicationController
  before_action :set_company

  def create
    @movement = @company.movements.new(movement_params)
    @movement.creator = current_user
    @movement.category_id = @company.subcategories.find_by(id: @movement.subcategory_id)&.category_id
    @movement.related_account_id = nil unless @movement.transfer?

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
    @company = current_user.company
  end

  def accounts
    @company.accounts.order(:name)
  end

  def categories
    @company.categories.includes(:subcategories).order(:id)
  end
  helper_method :accounts, :categories

  def movement_params
    params.require(:movement).permit(:mv_type, :amount, :occurred_at, :description, :account_id, :subcategory_id, :related_account_id)
  end
end
