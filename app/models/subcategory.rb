class Subcategory < ApplicationRecord
  belongs_to :company
  belongs_to :category
  has_many :movements, dependent: :nullify

  validates :name, presence: true
end
