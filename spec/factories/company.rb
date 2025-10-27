FactoryBot.define do
  factory :company do
    name { "Empresa Exemplo Ltda" }
    cnpj { "12.345.678/0001-99" }
    address { "Rua das Flores, 123" }
  end
end
