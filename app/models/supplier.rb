class Supplier < ApplicationRecord
  belongs_to :company
  has_many :product_suppliers, dependent: :destroy
  has_many :products, through: :product_suppliers
  has_many :stock_entries, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :ordered, -> { order(:name) }
  scope :active, -> { where(active: true) }
end
