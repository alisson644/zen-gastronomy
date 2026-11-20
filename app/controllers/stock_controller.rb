# Visão geral do estoque: quantidades, valor e alertas de estoque baixo.
class StockController < ApplicationController
  requires_permission "stock.view"
  before_action :require_company!

  def show
    @products = current_company.products.active.ordered
    @stock_value = @products.sum("quantity * average_cost")
    @low_stock_count = @products.count(&:low_stock?)
    @stock_movements = current_company.stock_movements.recent.includes(:product, :creator).limit(15)
  end
end
