# O app é renderizado no servidor e não tem API: por padrão nenhuma outra origem é liberada.
# Para liberar um front/app externo, defina CORS_ORIGINS (separadas por vírgula), ex.:
#   CORS_ORIGINS="https://app.exemplo.com,https://admin.exemplo.com"
# Cookies nunca são enviados entre origens (credentials: false), para não enfraquecer o CSRF.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, _env|
      ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).compact_blank.include?(source)
    end

    resource "*",
             headers: :any,
             methods: %i[get post patch put delete options head],
             credentials: false,
             max_age: 600
  end
end
