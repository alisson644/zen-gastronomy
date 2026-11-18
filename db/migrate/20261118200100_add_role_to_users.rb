class AddRoleToUsers < ActiveRecord::Migration[8.0]
  # Perfis padrão criados aqui com SQL simples para não depender do model.
  DEFAULTS = {
    "admin" => [ "Administrador do sistema", %w[dashboard.view financial.view movements.create accounts.manage categories.manage team.manage companies.view_all roles.manage] ],
    "dono" => [ "Dono", %w[dashboard.view financial.view movements.create accounts.manage categories.manage team.manage] ],
    "administrativo" => [ "Administrativo", %w[financial.view movements.create] ]
  }.freeze

  def up
    add_reference :users, :role, foreign_key: true

    DEFAULTS.each do |key, (name, permissions)|
      execute <<~SQL
        INSERT INTO roles (name, key, system, permissions, created_at, updated_at)
        VALUES (#{quote(name)}, #{quote(key)}, TRUE, #{quote("{#{permissions.join(",")}}")}, NOW(), NOW())
        ON CONFLICT (key) DO NOTHING
      SQL
    end

    # Usuários existentes criaram as próprias empresas: viram "dono".
    execute "UPDATE users SET role_id = (SELECT id FROM roles WHERE key = 'dono') WHERE role_id IS NULL"
    change_column_null :users, :role_id, false
  end

  def down
    remove_reference :users, :role, foreign_key: true
  end

  private

  def quote(value)
    connection.quote(value)
  end
end
