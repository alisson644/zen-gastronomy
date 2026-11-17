require 'rails_helper'

RSpec.describe Company, type: :model do
  it { should have_many(:users).dependent(:destroy) }
  it { should have_many(:accounts).dependent(:destroy) }
  it { should have_many(:categories).dependent(:destroy) }
  it { should have_many(:subcategories).dependent(:destroy) }
  it { should have_many(:movements).dependent(:destroy) }

  it { should validate_presence_of(:name) }
  it { should validate_length_of(:cnpj).is_at_most(20) }
end
