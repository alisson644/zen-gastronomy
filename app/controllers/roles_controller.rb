# Perfis da empresa: o dono (ou o admin do sistema visualizando a empresa) define
# o que cada perfil pode fazer e cria perfis novos.
class RolesController < ApplicationController
  requires_permission "roles.manage"
  before_action :require_company!
  before_action :set_role, only: [ :edit, :update, :destroy ]

  def index
    @roles = current_company.roles.ordered.left_joins(:users).select("roles.*, COUNT(users.id) AS users_count").group("roles.id")
  end

  def new
    @role = current_company.roles.new
  end

  def create
    @role = current_company.roles.new(role_params)
    if @role.save
      redirect_to roles_path, notice: "Perfil #{@role.name} criado."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    attrs = @role.locked? ? role_params.except(:permissions) : role_params
    if @role.update(attrs)
      redirect_to roles_path, notice: "Perfil #{@role.name} atualizado."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @role.destroy
      redirect_to roles_path, notice: "Perfil #{@role.name} excluído.", status: :see_other
    else
      redirect_to roles_path, alert: @role.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_role
    @role = current_company.roles.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, permissions: [])
  end
end
