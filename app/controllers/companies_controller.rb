class CompaniesController < ApplicationController
  def index
  end

  def show
    @company = Company.find(params[:id])
  end

  def new
    @company = Company.new
  end
  def create
    @company = Company.new(company_params)
    if @company.save
      @user = User.find(current_user.id)
      @user.company = @company
      if @user.save
        redirect_to root_path
      end
    end
  end


  def edit
  end

  def update
  end

  def destroy
  end

  private

  def company_params
    params.permit(:name, :cnpj, :address)
  end
end
