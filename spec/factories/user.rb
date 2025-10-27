FactoryBot.define do
  factory :user do
    association :company
    username { "João Silva" }
    email { Faker::Internet.unique.email }
    encrypted_password { "hash_senha" }
    password { "hash_senha" }
  end
end
