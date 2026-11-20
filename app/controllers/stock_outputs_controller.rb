# Saída manual de estoque (consumo, perda, vencido). Não gera lançamento no financeiro.
class StockOutputsController < ApplicationController
  requires_permission "stock.entries"
  before_action :require_company!

  def new
    @output = current_company.stock_movements.new(kind: :saida, reason: "consumo")
  end

  def create
    @output = current_company.stock_movements.new(output_params.merge(kind: :saida, creator: current_user))
    if @output.save
      redirect_to stock_path, notice: "Saída de #{@output.product.name} registrada."
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def output_params
    params.require(:stock_movement).permit(:product_id, :quantity, :reason, :notes)
  end
end
