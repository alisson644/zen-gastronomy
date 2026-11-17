class CategoriesController < ApplicationController
  before_action :set_company

  def create
    @category = @company.categories.new(category_params)
    subcategory_name = params.dig(:category, :subcategory_name).to_s.strip

    Category.transaction do
      @category.save!
      @subcategory = @company.subcategories.create!(category: @category, name: subcategory_name) if subcategory_name.present?
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to financial_index_path, notice: "Categoria criada com sucesso." }
    end
  rescue ActiveRecord::RecordInvalid
    render turbo_stream: turbo_stream.replace("category_form", partial: "partials/category_form", locals: { category: @category }),
           status: :unprocessable_content
  end

  private

  def set_company
    @company = current_user.company
  end

  def category_params
    params.require(:category).permit(:name, :is_income)
  end
end
