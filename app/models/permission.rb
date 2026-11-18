# Catálogo de permissões. Cada chave é checada em algum ponto do código
# (controllers via `requires_permission`, views via `current_user.can?`).
# Perfis (Role) são combinações editáveis destas permissões.
module Permission
  ALL = {
    "dashboard.view" => "Ver dashboard",
    "financial.view" => "Ver financeiro",
    "movements.create" => "Cadastrar transações",
    "accounts.manage" => "Cadastrar contas",
    "categories.manage" => "Cadastrar categorias e subcategorias",
    "team.manage" => "Gerenciar equipe da empresa",
    "roles.manage" => "Gerenciar perfis da empresa",
    "companies.view_all" => "Ver todas as empresas"
  }.freeze

  # Permissões que valem para o sistema inteiro: só o Administrador do sistema tem.
  GLOBAL = %w[companies.view_all].freeze

  # Permissões que uma empresa pode distribuir nos próprios perfis.
  COMPANY = (ALL.keys - GLOBAL).freeze

  def self.label(key) = ALL.fetch(key.to_s)
  def self.global?(key) = GLOBAL.include?(key.to_s)
end
