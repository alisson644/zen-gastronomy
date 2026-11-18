# Equipe da empresa: o dono cadastra e remove os usuários (ex.: administrativos).
class TeamMembersController < ApplicationController
  requires_permission "team.manage"
  before_action :require_company!

  def index
    @members = current_company.users.includes(:role, avatar_attachment: :blob).order(:username)
  end

  def new
    @member = current_company.users.new(role: current_company.roles.find_by(key: "administrativo"))
    @roles = assignable_roles
  end

  def create
    @member = current_company.users.new(member_params.except(:role_id))
    # Só perfis da própria empresa (o Administrador do sistema é global e nunca aparece aqui).
    @member.role = assignable_roles.find_by(id: member_params[:role_id])

    if @member.role.present? && @member.save
      redirect_to team_members_path, notice: "#{@member.username} foi adicionado(a) à equipe."
    else
      @member.errors.add(:role, "inválido") if @member.role.blank?
      @roles = assignable_roles
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    member = current_company.users.find(params[:id])

    if member == current_user
      redirect_to team_members_path, alert: "Você não pode remover a si mesmo.", status: :see_other
    elsif member.destroy
      redirect_to team_members_path, notice: "#{member.username} foi removido(a) da equipe.", status: :see_other
    else
      redirect_to team_members_path, alert: member.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def assignable_roles
    current_company.roles.ordered
  end

  def member_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :role_id)
  end
end
