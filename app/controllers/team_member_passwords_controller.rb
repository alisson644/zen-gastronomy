# Quem gerencia a equipe (Dono, ou o admin do sistema visualizando a empresa)
# define uma nova senha para um membro da empresa.
class TeamMemberPasswordsController < ApplicationController
  requires_permission "team.manage"
  before_action :require_company!
  before_action :set_member

  def edit
  end

  def update
    password = password_params[:password].to_s

    if password.blank?
      @member.errors.add(:password, "não pode ficar em branco")
      render :edit, status: :unprocessable_content
    elsif @member.update(password: password, password_confirmation: password_params[:password_confirmation].to_s)
      redirect_to team_members_path, notice: "Senha de #{@member.username} alterada.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_member
    @member = current_company.users.find(params[:team_member_id])
    return unless @member == current_user

    redirect_to edit_user_registration_path, alert: "Para trocar a sua própria senha, use o Perfil.", status: :see_other
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
