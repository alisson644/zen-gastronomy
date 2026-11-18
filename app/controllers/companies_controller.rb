class CompaniesController < ApplicationController
  def create
    @company = Company.new(company_params)
    if @company.save
      current_user.update!(company: @company, role: @company.roles.find_by!(key: Role::OWNER_KEY))
      redirect_to root_path
    else
      redirect_to root_path, alert: @company.errors.full_messages.to_sentence
    end
  end

  private

  def company_params
    params.permit(:name, :cnpj, :address)
  end
end
