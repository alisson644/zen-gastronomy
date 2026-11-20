FactoryBot.define do
  factory :product do
    association :company
    sequence(:name) { |n| "Produto #{n}" }
    unit { "kg" }
    min_quantity { 2 }
    sale_price { 25 }
  end
end
