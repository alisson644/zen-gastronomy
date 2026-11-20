class ProductsController < ApplicationController
  requires_permission "products.manage"
  before_action :require_company!
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @products = current_company.products.ordered.includes(:suppliers)
  end

  def show
    @product_suppliers = @product.product_suppliers.includes(:supplier).joins(:supplier).order("suppliers.name")
    @stock_movements = @product.stock_movements.recent.includes(:creator).limit(20)
  end

  def new
    @product = current_company.products.new
    @product.product_suppliers.build
  end

  def create
    @product = current_company.products.new(product_params)
    if @product.save
      redirect_to product_path(@product), notice: "Produto #{@product.name} cadastrado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to product_path(@product), notice: "Produto #{@product.name} atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @product.destroy
      redirect_to products_path, notice: "Produto #{@product.name} excluído.", status: :see_other
    else
      redirect_to product_path(@product), status: :see_other,
                  alert: "#{@product.name} já tem movimentações de estoque e não pode ser excluído; desative-o."
    end
  end

  private

  def set_product
    @product = current_company.products.find(params[:id])
  end

  # Quantidade e custo médio só mudam por movimentações de estoque. Subcategoria e fornecedores
  # de outra empresa são barrados pelas validações de Product e ProductSupplier.
  def product_params
    params.require(:product).permit(:name, :code, :unit, :min_quantity, :sale_price, :subcategory_id, :active,
                                    product_suppliers_attributes: [ :id, :supplier_id, :supplier_code, :last_price, :_destroy ])
  end
end
