# Limite de requisições e bloqueio de abuso (força bruta no login, enumeração, scanners).
# Contadores ficam no Rails.cache (Solid Cache em produção). Desligado em test, exceto no
# spec/requests/rack_attack_spec.rb, que o liga explicitamente.
class Rack::Attack
  SCANNER_PATHS = %r{\A/(wp-admin|wp-login|wp-content|wp-includes|xmlrpc|phpmyadmin|cgi-bin|\.env|\.git|\.aws|config\.json)|\.(php|asp|aspx|jsp|cgi)\z}i

  self.cache.store = Rails.env.test? ? ActiveSupport::Cache::MemoryStore.new : Rails.cache
  self.enabled = !Rails.env.test?

  def self.normalized_email(req)
    req.params.dig("user", "email").to_s.downcase.strip.presence
  end

  safelist("health check") { |req| req.path == "/up" }

  # Login
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.post? && req.path == "/users/sign_in"
  end
  throttle("logins/email", limit: 5, period: 1.minute) do |req|
    normalized_email(req) if req.post? && req.path == "/users/sign_in"
  end

  # Recuperação de senha
  throttle("password_resets/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/users/password"
  end
  throttle("password_resets/email", limit: 3, period: 1.hour) do |req|
    normalized_email(req) if req.post? && req.path == "/users/password"
  end

  # Cadastro
  throttle("sign_ups/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/users"
  end

  # Geral (assets e favicon ficam de fora)
  throttle("requests/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets") || req.path.start_with?("/icon")
  end

  # Quem procura caminhos de WordPress/PHP/.env é bloqueado e, após 3 tentativas, banido por 1h.
  blocklist("scanners") do |req|
    Rack::Attack::Fail2Ban.filter("scanners/#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.hour) do
      SCANNER_PATHS.match?(req.path)
    end
  end

  self.throttled_responder = lambda do |request|
    match = request.env["rack.attack.match_data"] || {}
    period = match[:period].to_i
    retry_after = period.positive? ? period - (Time.now.to_i % period) : 60
    [ 429,
      { "content-type" => "text/plain; charset=utf-8", "retry-after" => retry_after.to_s },
      [ "Muitas tentativas. Aguarde #{retry_after} segundos e tente novamente." ] ]
  end

  self.blocklisted_responder = lambda do |_request|
    [ 403, { "content-type" => "text/plain; charset=utf-8" }, [ "Acesso bloqueado." ] ]
  end
end
