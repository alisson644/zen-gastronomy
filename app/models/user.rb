class User < ApplicationRecord
  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  AVATAR_MAX_SIZE = 2.megabytes

  belongs_to :company, optional: true
  accepts_nested_attributes_for :company
  belongs_to :role, optional: true
  has_many :movements, foreign_key: :created_by_id, dependent: :destroy
  has_one_attached :avatar

  attribute :remove_avatar, :boolean, default: false

  validates :username, presence: true

  validates :role, presence: true, if: -> { company.present? }
  validate :role_from_own_company
  validate :avatar_format

  after_save :purge_avatar, if: -> { remove_avatar && !attachment_changes.key?("avatar") }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def can?(permission)
    role.present? && role.allows?(permission)
  end

  def system_admin?
    can?("companies.view_all")
  end

  private

  # Perfis são da empresa; só o Administrador do sistema (global) vale para qualquer usuário.
  def role_from_own_company
    return if role.nil? || role.company_id.nil? || role.company == company

    errors.add(:role, "não pertence a esta empresa")
  end

  def avatar_format
    return unless avatar.attached?

    unless AVATAR_CONTENT_TYPES.include?(avatar.blob.content_type)
      errors.add(:avatar, "deve ser PNG, JPG ou WEBP")
    end

    if avatar.blob.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "deve ter no máximo 2 MB")
    end
  end

  def purge_avatar
    avatar.purge_later
    self.remove_avatar = false
  end
end
