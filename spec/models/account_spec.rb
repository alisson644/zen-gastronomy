require 'rails_helper'

RSpec.describe Account, type: :model do
  it { should belong_to(:company) }
  it { should have_many(:movements).dependent(:destroy) }

 it { should validate_presence_of(:name) }
 it { should validate_presence_of(:account_type) }
 it { should validate_numericality_of(:current_balance) }
 it { should define_enum_for(:account_type).with_values([ :banco, :caixa, :investimento, :cartao, :outros ]) }
 it { should validate_numericality_of(:initial_balance) }
end
