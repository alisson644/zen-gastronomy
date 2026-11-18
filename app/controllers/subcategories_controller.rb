class SubcategoriesController < ApplicationController
  requires_permission "categories.manage"
  before_action :require_company!
  before_action :set_company

  def create
    @subcategory = @company.subcategories.new(subcategory_params)
    # Only accept categories that belong to the current company
    @subcategory.category = @company.categories.find_by(id: subcategory_params[:category_id])

    if @subcategory.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to financial_index_path, notice: "Subcategoria criada com sucesso." }
      end
    else
      render turbo_stream: turbo_stream.replace("subcategory_form", partial: "partials/subcategory_form",
                                                locals: { subcategory: @subcategory, categories: @company.categories.order(:id) }),
             status: :unprocessable_content
    end
  end

  private

  def set_company
    @company = current_company
  end

  def subcategory_params
    params.require(:subcategory).permit(:name, :category_id)
  end
end
