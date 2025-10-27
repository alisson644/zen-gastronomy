require 'rails_helper'

RSpec.describe Subcategory, type: :model do
  it { should belong_to(:company) }
  it { should have_many(:movements).dependent(:nullify) }
  it { should belong_to(:category) }

  it { should validate_presence_of(:name) }
end
