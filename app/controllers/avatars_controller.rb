# Salva somente a foto do usuário, sem exigir a senha atual
# (a edição dos demais dados continua no Devise::RegistrationsController).
class AvatarsController < ApplicationController
  before_action :authenticate_user!

  def update
    file = params.dig(:user, :avatar)

    if file.blank?
      redirect_to edit_user_registration_path, alert: "Selecione uma foto.", status: :see_other
    elsif current_user.update(avatar: file)
      redirect_to edit_user_registration_path, notice: "Foto atualizada.", status: :see_other
    else
      redirect_to edit_user_registration_path, alert: "Foto #{current_user.errors[:avatar].to_sentence}.", status: :see_other
    end
  end
end
