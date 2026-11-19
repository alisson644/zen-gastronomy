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
end
