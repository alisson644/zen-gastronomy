# Perfis passam a pertencer a cada empresa. Só o "Administrador do sistema" continua global.
# Cada empresa recebe cópias de Dono/Administrativo (e de perfis customizados que ela usava),
# e os usuários são remapeados para as cópias da própria empresa.
class ScopeRolesToCompanies < ActiveRecord::Migration[8.0]
  class MigrationRole < ActiveRecord::Base
    self.table_name = "roles"
  end

  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationCompany < ActiveRecord::Base
    self.table_name = "companies"
  end

  COMPANY_PERMISSIONS = %w[dashboard.view financial.view movements.create accounts.manage categories.manage team.manage roles.manage].freeze

  def up
    add_reference :roles, :company, foreign_key: true
    remove_index :roles, :name
    remove_index :roles, :key
    add_index :roles, [ :company_id, :name ], unique: true
    add_index :roles, [ :company_id, :key ], unique: true
    add_index :roles, :name, unique: true, where: "company_id IS NULL", name: "index_roles_on_global_name"
    add_index :roles, :key, unique: true, where: "company_id IS NULL", name: "index_roles_on_global_key"
    change_column_null :users, :role_id, true

    MigrationRole.reset_column_information
    global_roles = MigrationRole.where(company_id: nil).where("key IS NULL OR key <> 'admin'")

    MigrationCompany.find_each do |company|
      copies = {}
      copy_for = lambda do |role|
        copies[role.id] ||= MigrationRole.create!(
          company_id: company.id, name: role.name, key: role.key, system: role.system,
          permissions: role.key == "dono" ? COMPANY_PERMISSIONS : role.permissions - %w[companies.view_all]
        )
      end

      %w[dono administrativo].each do |key|
        role = global_roles.find_by(key: key)
        copy_for.call(role) if role
      end

      MigrationUser.where(company_id: company.id, role_id: global_roles.select(:id)).find_each do |user|
        user.update_columns(role_id: copy_for.call(MigrationRole.find(user.role_id)).id)
      end
    end

    # Quem ainda não tem empresa recebe o perfil "Dono" ao criá-la.
    MigrationUser.where(company_id: nil, role_id: global_roles.select(:id)).update_all(role_id: nil)
    global_roles.delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
