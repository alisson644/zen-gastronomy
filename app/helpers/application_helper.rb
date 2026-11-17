module ApplicationHelper
  # Formata um valor em reais: R$ 1.234,56
  def brl(value)
    number_to_currency(value || 0, unit: "R$ ", separator: ",", delimiter: ".", precision: 2, format: "%u%n", negative_format: "-%u%n")
  end
end
