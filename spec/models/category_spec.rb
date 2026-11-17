require 'rails_helper'

RSpec.describe Category, type: :model do
  it { should belong_to(:company) }
  it { should have_many(:movements).dependent(:nullify) }
  it { should have_many(:subcategories).dependent(:destroy) }

  it { should validate_presence_of(:name) }
end
