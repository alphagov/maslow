source 'https://rubygems.org'

gem 'rails', '~> 5.2.3'

gem 'dalli', '~> 2.7'
gem 'govspeak', '~> 6'
gem 'mongoid', '~> 6'
gem 'plek', '~> 2'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '~> 14'
end

gem 'cancancan', '~> 3'
gem 'kaminari', '~> 1'

gem 'sass-rails', '~> 5'
gem 'uglifier', '~> 4'

gem 'chosen-rails'

gem 'formtastic', '~> 3'
gem 'formtastic-bootstrap', '~> 3'
gem 'govuk_admin_template', '~> 6'

if ENV['API_DEV']
  gem 'gds-api-adapters', path: '../gds-api-adapters'
else
  gem 'gds-api-adapters', '~> 59'
end

gem 'govuk_app_config', '~> 1'

group :test do
  gem 'capybara', '~> 3'
  gem 'database_cleaner', '~> 1', require: false
  gem 'factory_bot_rails', '~> 5'
  gem 'mocha', '~> 1', require: false
  gem 'pry-byebug'
  gem 'rails-controller-testing', '~> 1'
  gem 'shoulda-context', '~> 1'
  gem 'test-unit'
  gem 'timecop', '~> 0.9'
  gem 'webmock', '~> 3'
end

group :development, :test do
  gem 'govuk-lint'
  gem 'jasmine', '~> 3'
end
