class HomeController < ApplicationController
  def index
    return unless user_signed_in?
    return if current_user.company.blank?

    @company = current_user.company
    @summary = DashboardSummary.new(@company, month: DashboardSummary.parse_month(params[:month]))
  end
end
