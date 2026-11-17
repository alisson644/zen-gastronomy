class Movement < ApplicationRecord
  include BrazilianDecimal
  brazilian_decimal :amount

  belongs_to :company
  belongs_to :account
  belongs_to :category
  belongs_to :subcategory
  belongs_to :creator, class_name: "User", foreign_key: :created_by_id
  belongs_to :related_account, class_name: "Account", optional: true

  enum :mv_type, [ :entrada, :saida, :transfer ]

  validates :amount, numericality: { greater_than: 0 }
  validates :occurred_at, presence: true
  validates :mv_type, presence: true
  validate :accounts_belong_to_company
  validate :related_account_presence_for_transfer
  validate :related_account_differs_from_account

  before_update :store_old_state
  after_create  :apply_effect!
  after_update  :apply_update_effect!
  after_destroy :revert_effect!

  # ---------- Balance logic ----------
  # Amount is always positive. Sign is determined by tx_type:
  # entrada => +amount on account
  # saida   => -amount on account
  # transfer => -amount on account_id, +amount on related_account_id
  private

  # Before update we capture the previous state so we can revert it after save
  def store_old_state
    @old_state = {
      mv_type: mv_type_was || mv_type, # mv_type_was may be nil in some rails versions
      account_id: account_id_was || account_id,
      related_account_id: related_account_id_was || related_account_id,
      amount: amount_was || amount
    }
  end

  def accounts_belong_to_company
    if account && account.company_id != company_id
      errors.add(:account, "must belong to the same company")
    end

    if related_account && related_account.company_id != company_id
      errors.add(:related_account, "must belong to the same company as transaction")
    end
  end

  def related_account_presence_for_transfer
    if mv_type == "transfer" && related_account_id.blank?
      errors.add(:related_account, "must be present for transfers")
    end
  end

  def related_account_differs_from_account
    if mv_type == "transfer" && related_account_id.present? && related_account_id == account_id
      errors.add(:related_account, "must be different from the source account")
    end
  end

  def apply_effect!
    self.class.transaction do
      apply_delta(mv_type, account_id, related_account_id, amount)
    end
  end

  def apply_update_effect!
    # Revert old effect and apply new effect
    return unless @old_state

    self.class.transaction do
      revert_delta(@old_state[:mv_type], @old_state[:account_id], @old_state[:related_account_id], @old_state[:amount])
      apply_delta(mv_type, account_id, related_account_id, amount)
    end
  end

  def revert_effect!
    self.class.transaction do
      revert_delta(mv_type, account_id, related_account_id, amount)
    end
  end

  # Apply delta according to a mv state
  def apply_delta(a_mv_type, a_account_id, a_related_account_id, a_amount)
    delta = delta_for(a_mv_type, a_amount)

    # Apply to main account (debit/credit as sign)
    if a_account_id
      a = Account.lock.find(a_account_id)
      a.update!(current_balance: a.current_balance + delta)
      adjust_company_cash_if_cash_account!(a, delta)
    end

    # For transfers, credit the related account with +amount
    if a_mv_type.to_s == "transfer" && a_related_account_id.present?
      ra = Account.lock.find(a_related_account_id)
      ra.update!(current_balance: ra.current_balance + a_amount)
      adjust_company_cash_if_cash_account!(ra, a_amount)
    end
  end

  # Revert previously applied delta (opposite of apply)
  def revert_delta(a_mv_type, a_account_id, a_related_account_id, a_amount)
    delta = delta_for(a_mv_type, a_amount)

    if a_account_id
      a = Account.lock.find(a_account_id)
      a.update!(current_balance: a.current_balance - delta)
      adjust_company_cash_if_cash_account!(a, -delta)
    end

    if a_mv_type.to_s == "transfer" && a_related_account_id.present?
      ra = Account.lock.find(a_related_account_id)
      ra.update!(current_balance: ra.current_balance - a_amount)
      adjust_company_cash_if_cash_account!(ra, -a_amount)
    end
  end

  # Returns signed delta to apply to "account" (main account)
  def delta_for(a_mv_type, a_amount)
    case a_mv_type.to_s
    when "entrada" then a_amount
    when "saida"   then -a_amount
    when "transfer" then -a_amount
    else 0
    end
  end

  # If the account is type 'cash', reflect change in company.cash_balance
  def adjust_company_cash_if_cash_account!(account, delta)
    return unless account.account_type == "cash"

    comp = Company.lock.find(account.company_id)
    comp.update!(current_balance: comp.current_balance + delta)
  end
end
