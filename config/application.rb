require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ZenGastronomy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # As chaves do Active Record Encryption (encrypts :cnpj) são lidas automaticamente de
    # credentials.active_record_encryption. Não as leia aqui: sem master key (build do Docker,
    # CI) isso quebra o boot.

    # Fuso do Brasil: datas de movimentações, entradas e CMV.
    config.time_zone = "Brasilia"

    # Permissions-Policy (o DSL config.permissions_policy do Rails ainda emite o cabeçalho
    # legado Feature-Policy, que os navegadores atuais ignoram).
    config.action_dispatch.default_headers["Permissions-Policy"] =
      "camera=(), microphone=(), geolocation=(), usb=(), payment=(), fullscreen=(self)"

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
  end
end
