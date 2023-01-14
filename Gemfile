source "https://rubygems.org"

gem "rails", "7.0.4"

gem "bootsnap", require: false
gem "cancancan"
gem "chosen-rails"
gem "dalli"
gem "gds-api-adapters"
gem "gds-sso"
gem "govspeak"
gem "govuk_admin_template"
gem "govuk_app_config"
gem "kaminari"
gem "mail", "~> 2.7.1" # TODO: remove once https://github.com/mikel/mail/issues/1489 is fixed.
gem "mongoid"
gem "plek"
gem "sassc-rails"
gem "uglifier"

group :test do
  gem "capybara"
  gem "database_cleaner-mongoid", require: false
  gem "factory_bot_rails"
  gem "mocha", require: false
  gem "pry-byebug"
  gem "rails-controller-testing"
  gem "shoulda-context"
  gem "simplecov"
  gem "webmock"
end

group :development, :test do
  gem "govuk_test"
  gem "rubocop-govuk", require: false
end
