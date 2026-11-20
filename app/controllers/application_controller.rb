class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_company, :viewing_company?, :stock_home_path

  # Empresa em uso: a do usuário ou, para o admin do sistema, a que ele escolheu visualizar.
  def current_company
    return @current_company if defined?(@current_company)

    @current_company =
      if current_user&.system_admin?
        Company.find_by(id: session[:viewing_company_id])
      else
        current_user&.company
      end
  end

  # Primeira tela do estoque que o usuário pode abrir (nil se nenhuma).
  def stock_home_path(user = current_user)
    return unless user

    if user.can?("stock.view") then stock_path
    elsif user.can?("stock.entries") then stock_entries_path
    elsif user.can?("stock.count") then stock_counts_path
    elsif user.can?("products.manage") then products_path
    elsif user.can?("suppliers.manage") then suppliers_path
    end
  end

  def viewing_company?
    current_user&.system_admin? && current_company.present?
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :avatar, { company_attributes: [ :name, :cnpj, :address ] } ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :avatar, :remove_avatar ])
  end

  def after_sign_in_path_for(user)
    stored_location_for(user) || home_path_for(user)
  end

  # Primeira tela que o usuário pode ver.
  def home_path_for(user)
    if user.system_admin? && current_company.blank?
      admin_companies_path
    elsif user.can?("dashboard.view")
      root_path
    elsif user.can?("financial.view")
      financial_index_path
    elsif stock_home_path(user)
      stock_home_path(user)
    else
      edit_user_registration_path
    end
  end

  def require_permission!(permission)
    return if current_user.can?(permission)

    if request.get? || request.head?
      redirect_to home_path_for(current_user), alert: "Você não tem permissão para acessar esta página."
    else
      head :forbidden
    end
  end

  # Telas que dependem de uma empresa (admin precisa escolher uma antes).
  def require_company!
    return if current_company.present?

    redirect_to current_user.system_admin? ? admin_companies_path : root_path
  end

  def self.requires_permission(permission, **options)
    before_action(-> { require_permission!(permission) }, **options)
  end
end
