class HomeController < ApplicationController
  def index
    return unless user_signed_in?
    return if current_user.company.blank?

    @company = current_user.company
    @categories = @company.categories
    @subcategories = @company.subcategories
    @accounts = @company.accounts
  end
end
