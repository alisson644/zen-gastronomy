module StockHelper
  INPUT_CLASS = "block w-full rounded-md bg-white px-3 py-1.5 text-base text-gray-900 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600 sm:text-sm/6".freeze
  LABEL_CLASS = "block text-sm/6 font-medium text-gray-900".freeze
  PRIMARY_BUTTON = "rounded-md bg-indigo-600 px-3 py-2 text-center text-sm font-semibold text-white shadow-xs hover:bg-indigo-500".freeze
  SECONDARY_BUTTON = "rounded-md bg-white px-3 py-2 text-center text-sm font-semibold text-gray-900 shadow-xs outline-1 -outline-offset-1 outline-gray-300 hover:bg-gray-50".freeze

  STOCK_CONTROLLERS = %w[stock products suppliers stock_entries stock_outputs stock_counts].freeze

  # Destaca "Estoque" no menu em qualquer tela do módulo.
  def stock_section? = STOCK_CONTROLLERS.include?(controller_name)

  def stock_input_class = INPUT_CLASS
  def stock_label_class = LABEL_CLASS
  def stock_primary_button = PRIMARY_BUTTON
  def stock_secondary_button = SECONDARY_BUTTON

  # Quantidade no formato brasileiro sem zeros sobrando: 2,5 / 1.000 / -0,125
  def qty(value)
    return "—" if value.nil?

    number_with_precision(value, precision: 3, strip_insignificant_zeros: true, separator: ",", delimiter: ".")
  end

  # Valor para preencher um campo de texto no padrão brasileiro (sem separador de milhar).
  def decimal_field_value(value, precision: 2)
    return nil if value.nil?

    number_with_precision(value, precision: precision, strip_insignificant_zeros: precision > 2, separator: ",", delimiter: "")
  end

  def stock_movement_kind_label(movement)
    case movement.kind
    when "entrada" then "Entrada"
    when "saida" then "Saída#{" (#{movement.reason_label})" if movement.reason_label}"
    when "ajuste" then "Ajuste (conferência)"
    end
  end

  # Selects de subcategorias de despesa agrupadas por categoria.
  def expense_subcategory_options(company, selected)
    categories = company.categories.where(is_income: false).includes(:subcategories).order(:id)
    grouped = categories.filter_map do |category|
      next if category.subcategories.empty?

      [ category.name, category.subcategories.sort_by(&:name).map { |sub| [ sub.name, sub.id ] } ]
    end
    grouped_options_for_select(grouped, selected)
  end
end
