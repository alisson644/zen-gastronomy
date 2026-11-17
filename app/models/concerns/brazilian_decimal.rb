# Aceita valores no formato brasileiro ("1.234,56") em atributos decimais.
#
#   class Movement < ApplicationRecord
#     include BrazilianDecimal
#     brazilian_decimal :amount
#   end
#
# Strings com vírgula têm os pontos (milhar) removidos e a vírgula vira ponto.
# Strings sem vírgula ("150.50") e números são repassados sem alteração.
module BrazilianDecimal
  extend ActiveSupport::Concern

  def self.parse(value)
    return value unless value.is_a?(String) && value.include?(",")

    value.strip.delete(".").tr(",", ".")
  end

  class_methods do
    def brazilian_decimal(*attributes)
      attributes.each do |attribute|
        define_method(:"#{attribute}=") do |value|
          super(BrazilianDecimal.parse(value))
        end
      end
    end
  end
end
