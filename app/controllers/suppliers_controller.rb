class SuppliersController < ApplicationController
  requires_permission "suppliers.manage"
  before_action :require_company!
  before_action :set_supplier, only: [ :show, :edit, :update, :destroy ]

  def index
    @suppliers = current_company.suppliers.ordered.left_joins(:product_suppliers)
                                .select("suppliers.*, COUNT(product_suppliers.id) AS products_count").group("suppliers.id")
  end

  def show
    @product_suppliers = @supplier.product_suppliers.includes(:product).joins(:product).order("products.name")
    @entries = @supplier.stock_entries.recent.limit(10)
  end

  def new
    @supplier = current_company.suppliers.new
  end

  def create
    @supplier = current_company.suppliers.new(supplier_params)
    if @supplier.save
      redirect_to suppliers_path, notice: "Fornecedor #{@supplier.name} cadastrado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to suppliers_path, notice: "Fornecedor #{@supplier.name} atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @supplier.destroy
      redirect_to suppliers_path, notice: "Fornecedor #{@supplier.name} excluído.", status: :see_other
    else
      redirect_to suppliers_path, status: :see_other,
                  alert: "#{@supplier.name} tem entradas de estoque e não pode ser excluído. Você pode desativá-lo."
    end
  end

  private

  def set_supplier
    @supplier = current_company.suppliers.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(:name, :cnpj, :contact_name, :phone, :email, :notes, :active)
  end
end
