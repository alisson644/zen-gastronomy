require "rails_helper"

RSpec.describe ProductSupplier, type: :model do
  subject { create(:product_supplier) }

  it { should belong_to(:product) }
  it { should belong_to(:supplier) }
  it { should validate_uniqueness_of(:supplier_id).scoped_to(:product_id) }
  it { should validate_numericality_of(:last_price).is_greater_than_or_equal_to(0).allow_nil }

  it "requires product and supplier from the same company" do
    link = build(:product_supplier, supplier: create(:supplier))
    expect(link).not_to be_valid
    expect(link.errors[:supplier]).to be_present
  end
end
