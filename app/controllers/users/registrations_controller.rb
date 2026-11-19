# Cadastro em dois passos (conta → empresa): cria a empresa e o usuário dono juntos.
class Users::RegistrationsController < Devise::RegistrationsController
  def create
    build_resource(sign_up_params)
    resource.build_company if resource.company.nil?

    if save_with_company
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  private

  # O perfil "dono" só existe depois que a empresa é criada, então valida tudo antes
  # (ignorando o perfil) e salva empresa + usuário numa única transação.
  def save_with_company
    resource.valid?
    resource.errors.delete(:role)
    return false if resource.errors.any?

    ActiveRecord::Base.transaction do
      company = resource.company
      company.save!
      resource.role = company.roles.find_by!(key: Role::OWNER_KEY)
      resource.save!
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| resource.errors.add(:base, error.full_message) } unless e.record == resource
    false
  end
end
