FactoryBot.define do
  factory :supplier do
    association :company
    sequence(:name) { |n| "Fornecedor #{n}" }
    cnpj { "11.222.333/0001-44" }
    phone { "(11) 99999-0000" }
  end
end
