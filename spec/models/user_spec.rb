require 'rails_helper'

RSpec.describe User, type: :model do
  it { should belong_to(:company).optional(true) }
  it { should have_many(:movements).dependent(:destroy) }

  it { should validate_presence_of(:username) }
  it { should validate_presence_of(:email) }

  it "with unic email valid in company" do
    company = FactoryBot.create(:company)
    FactoryBot.create(:user, company_id: company.id, email: "test@example.com")
    user = FactoryBot.build(:user, company_id: company.id, email: "test@example.com")
    expect(user).not_to be_valid
  end
end
