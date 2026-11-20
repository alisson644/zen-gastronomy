class StockEntriesController < ApplicationController
  requires_permission "stock.entries"
  before_action :require_company!

  def index
    @entries = current_company.stock_entries.recent.includes(:supplier, :movement)
  end

  def show
    @entry = current_company.stock_entries.includes(items: :product).find(params[:id])
  end

  def new
    @entry = current_company.stock_entries.new(received_on: Date.current, payment_method: :pix)
    @entry.items.build
  end

  def create
    @entry = current_company.stock_entries.new(entry_params)
    @entry.creator = current_user
    @entry.supplier = current_company.suppliers.find_by(id: params.dig(:stock_entry, :supplier_id))
    @entry.account = current_company.accounts.find_by(id: params.dig(:stock_entry, :account_id))
    @entry.subcategory = current_company.subcategories.find_by(id: params.dig(:stock_entry, :subcategory_id))

    if StockEntryRegistration.new(@entry).save
      redirect_to stock_entry_path(@entry), notice: "Entrada registrada e lançada no financeiro."
    else
      @entry.items.build if @entry.items.empty?
      render :new, status: :unprocessable_content
    end
  end

  private

  # Fornecedor, conta e categoria são buscados pela empresa (create); produtos de outra
  # empresa são barrados pela validação de StockEntry.
  def entry_params
    params.require(:stock_entry).permit(:received_on, :payment_method, :due_on, :invoice_number, :notes,
                                        items_attributes: [ :product_id, :quantity, :unit_cost ])
  end
end
