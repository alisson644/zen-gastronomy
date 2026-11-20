require 'rails_helper'

RSpec.describe Movement, type: :model do
  it { should belong_to(:company) }
  it { should belong_to(:account) }
  it { should belong_to(:category).optional }
  it { should belong_to(:subcategory).optional }
  it { should belong_to(:creator) }

  it { should define_enum_for(:mv_type).with_values([ :entrada, :saida, :transfer ]) }
  it { should validate_numericality_of(:amount).is_greater_than(0) }
  it { should validate_presence_of(:occurred_at) }

  describe "category rules by type" do
    let(:user) { create(:user) }
    let(:company) { user.company }
    let(:account) { company.accounts.first }
    let(:other_account) { company.accounts.create!(name: "Banco", account_type: :banco, initial_balance: 0, current_balance: 0) }
    let(:income_sub) { company.subcategories.find_by!(name: "Pix") }
    let(:expense_sub) { company.subcategories.find_by!(name: "Aluguel") }

    def build_mv(type, sub, related: nil)
      company.movements.new(mv_type: type, amount: 10, occurred_at: Date.current, account: account,
                            subcategory: sub, category: sub&.category, creator: user, related_account: related)
    end

    it "requires a category for entrada and saida" do
      expect(build_mv(:entrada, nil)).not_to be_valid
      expect(build_mv(:saida, nil)).not_to be_valid
    end

    it "accepts an income category for entrada and rejects an expense one" do
      expect(build_mv(:entrada, income_sub)).to be_valid
      mv = build_mv(:entrada, expense_sub)
      expect(mv).not_to be_valid
      expect(mv.errors[:category]).to be_present
    end

    it "accepts an expense category for saida and rejects an income one" do
      expect(build_mv(:saida, expense_sub)).to be_valid
      expect(build_mv(:saida, income_sub)).not_to be_valid
    end

    it "does not require a category for transfers" do
      expect(build_mv(:transfer, nil, related: other_account)).to be_valid
    end
  end

  describe "pending (boleto) status" do
    let(:user) { create(:user) }
    let(:company) { user.company }
    let(:account) { company.accounts.create!(name: "Banco", account_type: :banco, initial_balance: 100, current_balance: 100) }
    let(:expense_sub) { company.subcategories.find_by!(name: "Aluguel") }
    let(:income_sub) { company.subcategories.find_by!(name: "Pix") }

    def create_mv(attrs = {})
      company.movements.create!({ mv_type: :saida, amount: 30, occurred_at: Date.current + 10, account: account,
                                  subcategory: expense_sub, category: expense_sub.category, creator: user }.merge(attrs))
    end

    it { should define_enum_for(:status).with_values(pendente: 0, pago: 1) }

    it "is paid by default and changes the balance" do
      mv = create_mv
      expect(mv).to be_pago
      expect(account.reload.current_balance).to eq(70)
    end

    it "does not touch the balance while pending" do
      create_mv(status: :pendente)
      expect(account.reload.current_balance).to eq(100)
    end

    it "applies the balance when paid" do
      mv = create_mv(status: :pendente)
      paid_at = Time.zone.parse("2026-11-20 10:00")
      mv.pay!(at: paid_at)
      expect(mv.reload).to be_pago
      expect(mv.paid_at).to eq(paid_at)
      expect(account.reload.current_balance).to eq(70)
    end

    it "does not revert anything when a pending movement is destroyed" do
      create_mv(status: :pendente).destroy!
      expect(account.reload.current_balance).to eq(100)
    end

    it "keeps the balance consistent when a pending movement changes amount" do
      mv = create_mv(status: :pendente)
      mv.update!(amount: 50)
      expect(account.reload.current_balance).to eq(100)
      mv.update!(status: :pago)
      expect(account.reload.current_balance).to eq(50)
    end

    it "reverts the balance when a paid movement goes back to pending" do
      mv = create_mv
      mv.update!(status: :pendente)
      expect(account.reload.current_balance).to eq(100)
    end

    it "only allows pending for expenses" do
      mv = company.movements.new(mv_type: :entrada, amount: 10, occurred_at: Date.current, account: account,
                                 subcategory: income_sub, category: income_sub.category, creator: user, status: :pendente)
      expect(mv).not_to be_valid
      expect(mv.errors[:status]).to be_present
    end
  end
end
