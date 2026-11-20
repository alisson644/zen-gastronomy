require "rails_helper"

RSpec.describe StockCount, type: :model do
  let(:user) { create(:user) }
  let(:company) { user.company }
  let!(:rice) { create(:product, company: company, name: "Arroz") }
  let!(:beans) { create(:product, company: company, name: "Feijão") }
  let!(:inactive) { create(:product, company: company, name: "Antigo", active: false) }

  before do
    company.stock_movements.create!(product: rice, kind: :entrada, quantity: 10, unit_cost: 5, creator: user)
    company.stock_movements.create!(product: beans, kind: :entrada, quantity: 4, unit_cost: 8, creator: user)
  end

  it { should belong_to(:company) }
  it { should belong_to(:creator).class_name("User").without_validating_presence }
  it { should validate_presence_of(:creator).on(:create) }
  it { should have_many(:items).dependent(:destroy) }
  it { should define_enum_for(:status).with_values(aberta: 0, finalizada: 1) }

  describe ".start!" do
    it "snapshots the current quantity of every active product" do
      count = described_class.start!(company: company, user: user)
      expect(count).to be_aberta
      expect(count.items.map { |i| [ i.product, i.expected_quantity ] }).to contain_exactly([ rice, 10 ], [ beans, 4 ])
    end

    it "allows only one open count per company" do
      described_class.start!(company: company, user: user)
      expect { described_class.start!(company: company, user: user) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#finalize!" do
    let(:count) { described_class.start!(company: company, user: user) }

    it "adjusts the stock to the counted quantities and keeps the differences" do
      count.items.find_by!(product: rice).update!(counted_quantity: "8,5")
      count.items.find_by!(product: beans).update!(counted_quantity: 4)

      count.finalize!(user)

      expect(count.reload).to be_finalizada
      expect(count.finished_at).to be_present
      expect(rice.reload.quantity).to eq(8.5)
      expect(beans.reload.quantity).to eq(4)
      expect(count.items.find_by!(product: rice).difference).to eq(-1.5)
      adjustments = company.stock_movements.ajuste
      expect(adjustments.count).to eq(1)
      expect(adjustments.first.source).to eq(count.items.find_by!(product: rice))
    end

    it "leaves uncounted items untouched" do
      count.finalize!(user)
      expect(rice.reload.quantity).to eq(10)
      expect(company.stock_movements.ajuste.count).to eq(0)
    end

    it "uses the quantity at finalization when stock moved during the count" do
      count.items.find_by!(product: rice).update!(counted_quantity: 12)
      company.stock_movements.create!(product: rice, kind: :entrada, quantity: 1, unit_cost: 5, creator: user)
      count.finalize!(user)
      expect(rice.reload.quantity).to eq(12)
    end

    it "cannot be finalized twice nor edited afterwards" do
      count.finalize!(user)
      expect { count.finalize!(user) }.to raise_error(ActiveRecord::RecordInvalid)
      item = count.items.first
      item.counted_quantity = 1
      expect(item).not_to be_valid
    end

    it "rejects a negative counted quantity" do
      expect(count.items.first.update(counted_quantity: -1)).to be false
    end
  end
end
