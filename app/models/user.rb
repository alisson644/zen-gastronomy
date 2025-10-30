class User < ApplicationRecord
  belongs_to :company, optional: true
  has_many :movements, foreign_key: :created_by_id, dependent: :destroy

  validates :username, presence: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
