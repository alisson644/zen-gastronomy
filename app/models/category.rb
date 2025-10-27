class Category < ApplicationRecord
  belongs_to :company
  has_many :movements, dependent: :nullify
  has_many :subcategories, dependent: :destroy

  validates :name, presence: true
end
