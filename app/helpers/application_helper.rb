module ApplicationHelper
  # Formata um valor em reais: R$ 1.234,56
  def brl(value)
    number_to_currency(value || 0, unit: "R$ ", separator: ",", delimiter: ".", precision: 2, format: "%u%n", negative_format: "-%u%n")
  end

  # Foto do usuário; usa a imagem padrão quando não há foto salva.
  def user_avatar_tag(user, css_class = "size-8", **options)
    source = user.avatar.attached? && user.avatar.persisted? ? url_for(user.avatar) : "avatar-default.svg"
    image_tag source, alt: "", class: "rounded-full object-cover #{css_class}", **options
  end
end
