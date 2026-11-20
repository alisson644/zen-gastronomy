FactoryBot.define do
  factory :product_supplier do
    product
    supplier { association :supplier, company: product.company }
    last_price { 10 }
  end
end
