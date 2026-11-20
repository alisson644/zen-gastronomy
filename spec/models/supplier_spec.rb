require "rails_helper"

RSpec.describe Supplier, type: :model do
  subject { build(:supplier) }

  it { should belong_to(:company) }
  it { should have_many(:product_suppliers).dependent(:destroy) }
  it { should have_many(:products).through(:product_suppliers) }
  it { should have_many(:stock_entries).dependent(:restrict_with_error) }
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).scoped_to(:company_id) }

  it "accepts a blank email but rejects an invalid one" do
    expect(build(:supplier, email: "")).to be_valid
    expect(build(:supplier, email: "contato@fornecedor.com")).to be_valid
    expect(build(:supplier, email: "nope")).not_to be_valid
  end

  it "allows the same name in another company" do
    supplier = create(:supplier, name: "Ceasa")
    expect(build(:supplier, name: "Ceasa", company: create(:company))).to be_valid
    expect(build(:supplier, name: "Ceasa", company: supplier.company)).not_to be_valid
  end
end
