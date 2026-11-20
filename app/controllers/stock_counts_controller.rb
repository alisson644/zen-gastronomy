class StockCountsController < ApplicationController
  requires_permission "stock.count"
  before_action :require_company!
  before_action :set_count, only: [ :show, :update, :finalize ]

  def index
    @counts = current_company.stock_counts.recent.includes(:creator)
    @open_count = current_company.stock_counts.aberta.first
  end

  def show
    @items = @count.items.includes(:product).joins(:product).order("products.name")
  end

  def create
    if (open_count = current_company.stock_counts.aberta.first)
      redirect_to stock_count_path(open_count), notice: "Já existe uma conferência aberta."
    else
      count = StockCount.start!(company: current_company, user: current_user)
      redirect_to stock_count_path(count), notice: "Conferência iniciada."
    end
  end

  def update
    return redirect_to(stock_count_path(@count), alert: "Esta conferência já foi finalizada.") if @count.finalizada?

    if @count.update(count_params)
      redirect_to stock_count_path(@count), notice: "Contagem salva."
    else
      @items = @count.items.includes(:product).joins(:product).order("products.name")
      render :show, status: :unprocessable_content
    end
  end

  def finalize
    @count.finalize!(current_user)
    redirect_to stock_count_path(@count), notice: "Conferência finalizada e estoque ajustado."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to stock_count_path(@count), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_count
    @count = current_company.stock_counts.find(params[:id])
  end

  def count_params
    params.require(:stock_count).permit(:notes, items_attributes: [ :id, :counted_quantity ])
  end
end
