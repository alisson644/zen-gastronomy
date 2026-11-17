FactoryBot.define do
  factory :user do
    association :company
    username { "João Silva" }
    sequence(:email) { |n| "user#{n}@example.com" }
    encrypted_password { "hash_senha" }
    password { "hash_senha" }
  end
end
