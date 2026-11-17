FactoryBot.define do
  factory :account do
    name { "MyString" }
    account_type { "cartao" }
    current_balance { "9.99" }
    initial_balance { "9.99" }
    association :company
  end
end
