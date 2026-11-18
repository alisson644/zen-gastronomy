class User < ApplicationRecord
  AVATAR_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  AVATAR_MAX_SIZE = 2.megabytes

  belongs_to :company, optional: true
  has_many :movements, foreign_key: :created_by_id, dependent: :destroy
  has_one_attached :avatar

  attribute :remove_avatar, :boolean, default: false

  validates :username, presence: true
  validate :avatar_format

  after_save :purge_avatar, if: -> { remove_avatar && !attachment_changes.key?("avatar") }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  private

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
