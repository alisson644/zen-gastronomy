class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    return unless user_signed_in?
    return if current_user.company.blank? && !current_user.system_admin? # modal "cadastrar empresa"
    return redirect_to(home_path_for(current_user)) unless current_user.can?("dashboard.view") && root_reachable?
    return if current_company.blank?

    @company = current_company
    @summary = DashboardSummary.new(@company, month: DashboardSummary.parse_month(params[:month]))
  end

  private

  # O admin só vê o dashboard quando está visualizando uma empresa.
  def root_reachable?
    !current_user.system_admin? || current_company.present?
  end
end
