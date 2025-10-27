class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :subcategories, dependent: :destroy
  has_many :movements, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :cnpj, length: { maximum: 20 }, allow_blank: true
end
