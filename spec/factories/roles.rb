FactoryBot.define do
  factory :role do
    association :company
    sequence(:name) { |n| "Perfil #{n}" }
    permissions { %w[financial.view] }
  end
end
