# Perfil de acesso. Cada empresa tem os próprios perfis (Dono, Administrativo e os que criar);
# o "Administrador do sistema" é o único perfil global (company_id nulo).
class Role < ApplicationRecord
  ADMIN_KEY = "admin".freeze
  OWNER_KEY = "dono".freeze

  COMPANY_DEFAULTS = {
    "dono" => { name: "Dono", permissions: Permission::COMPANY },
    "administrativo" => { name: "Administrativo", permissions: %w[financial.view movements.create] }
  }.freeze

  belongs_to :company, optional: true
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :key, uniqueness: { scope: :company_id }, allow_nil: true
  validate :permissions_in_catalog

  before_destroy :prevent_default_destroy, prepend: true

  scope :ordered, -> { order(system: :desc, name: :asc) }

  def self.admin!
    find_or_create_by!(company_id: nil, key: ADMIN_KEY) do |role|
      role.name = "Administrador do sistema"
      role.permissions = Permission::ALL.keys
      role.system = true
    end
  end

  def self.create_defaults_for!(company)
    COMPANY_DEFAULTS.each do |key, attrs|
      company.roles.find_or_create_by!(key: key) do |role|
        role.name = attrs[:name]
        role.permissions = attrs[:permissions]
        role.system = true
      end
    end
  end

  def permissions=(values)
    super(Array(values).map(&:to_s).compact_blank.uniq)
  end

  def admin? = key == ADMIN_KEY && company_id.nil?
  def owner? = key == OWNER_KEY && company_id.present?

  # Admin e Dono têm as permissões fixas (inclusive as que forem criadas no futuro).
  def locked? = admin? || owner?

  def effective_permissions
    if admin? then Permission::ALL.keys
    elsif owner? then Permission::COMPANY
    else permissions
    end
  end

  def allows?(permission)
    effective_permissions.include?(permission.to_s)
  end

  private

  def permissions_in_catalog
    allowed = company_id.nil? ? Permission::ALL.keys : Permission::COMPANY
    invalid = permissions - allowed
    errors.add(:permissions, "não permitidas: #{invalid.join(", ")}") if invalid.any?
  end

  def prevent_default_destroy
    return unless system? && !destroyed_by_association

    errors.add(:base, "Perfis padrão não podem ser excluídos")
    throw :abort
  end
end
