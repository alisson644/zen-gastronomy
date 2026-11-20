# Content Security Policy. Ver https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# - script-src: só os nossos scripts (com nonce) e o @tailwindplus/elements do jsDelivr.
# - style-src aceita 'unsafe-inline' porque há atributos style= nas views e a barra de progresso
#   do Turbo injeta <style>; por isso o nonce vale só para script-src (nonce em style-src
#   faria o navegador ignorar o 'unsafe-inline').
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self, "https://cdn.jsdelivr.net"
    policy.style_src   :self, :unsafe_inline
    policy.img_src     :self, :data, :blob
    policy.font_src    :self, :data
    policy.connect_src :self
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
  config.content_security_policy_nonce_auto = true
end
