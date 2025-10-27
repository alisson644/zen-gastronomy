require 'rails_helper'

RSpec.describe Movement, type: :model do
  it { should belong_to(:company) }
  it { should belong_to(:account) }
  it { should belong_to(:category) }
  it { should belong_to(:subcategory) }
  it { should belong_to(:creator) }

  it { should define_enum_for(:mv_type).with_values([ :entrada, :saida, :transfer ]) }
  it { should validate_numericality_of(:amount).is_greater_than(0) }
  it { should validate_presence_of(:occurred_at) }
end
