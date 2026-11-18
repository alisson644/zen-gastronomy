FactoryBot.define do
  factory :user do
    association :company
    username { "João Silva" }
    sequence(:email) { |n| "user#{n}@example.com" }
    encrypted_password { "hash_senha" }
    password { "hash_senha" }
    # Por padrão, dono da própria empresa (sem empresa, sem perfil — como logo após o cadastro).
    role { company&.roles&.find_by(key: "dono") }

    trait :dono

    trait :administrativo do
      role { company.roles.find_by!(key: "administrativo") }
    end

    trait :admin do
      company { nil }
      role { Role.admin! }
    end
  end
end
