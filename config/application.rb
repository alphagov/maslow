require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Maslow
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    config.time_zone = "London"

    # TODO: remove once upgraded to Rails 7
    config.active_support.cache_format_version = 6.1

    # Rotate SHA1 cookies to SHA256 (the new Rails 7 default)
    # TODO: Remove this after existing user sessions have been rotated
    # https://guides.rubyonrails.org/v7.0/upgrading_ruby_on_rails.html#key-generator-digest-class-changing-to-use-sha256
    Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
      salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
      secret_key_base = Rails.application.secrets.secret_key_base
      next if secret_key_base.blank?

      key_generator = ActiveSupport::KeyGenerator.new(
        secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
      )
      key_len = ActiveSupport::MessageEncryptor.key_len
      secret = key_generator.generate_key(salt, key_len)

      cookies.rotate :encrypted, secret
    end

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = true

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = "1.0"

    # Using a sass css compressor causes a scss file to be processed twice
    # (once to build, once to compress) which breaks the usage of "unquote"
    # to use CSS that has same function names as SCSS such as max.
    # https://github.com/alphagov/govuk-frontend/issues/1350
    config.assets.css_compressor = nil
  end
end
