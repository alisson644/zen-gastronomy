class Account < ApplicationRecord
  include BrazilianDecimal
  brazilian_decimal :initial_balance, :current_balance

  belongs_to :company
  has_many :movements, dependent: :destroy
  has_many :related_transactions, class_name: "Movement", foreign_key: :related_account_id


  enum :account_type, [ :banco, :caixa, :investimento, :cartao, :outros ]

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :account_type, presence: true
  validates :current_balance, numericality: true
  validates :initial_balance, numericality: true
end
