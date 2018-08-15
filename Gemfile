source 'https://rubygems.org'

gem 'rails', '~> 5.2.1'

gem 'mongoid', '6.1.1'
gem 'plek', '~> 2.1.1'
gem 'govspeak', '~> 5'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '~> 13.6'
end

gem 'kaminari', '1.1.1'
gem 'cancancan', '2.2.0'
gem 'lrucache', '0.1.4'

group :test do
  gem 'pry-byebug'
  gem 'webmock', '~> 3.4.2'
  gem 'test-unit'
  gem 'capybara', '3.5.1'
  gem 'database_cleaner', '1.7.0', require: false
  gem 'factory_bot_rails', '4.10.0'
  gem 'rails-controller-testing', '1.0.2'
  gem 'shoulda-context', '1.2.2'
  gem 'mocha', '1.7.0', require: false
  gem 'timecop', '0.9.1'
end

group :development, :test do
  gem 'govuk-lint'
  gem 'jasmine', '3.2.0'
end

gem 'sass-rails', '~> 5.0.3'
gem 'uglifier', '4.1.18'

gem 'chosen-rails'

gem 'govuk_admin_template', '6.6.0'
gem 'formtastic', '~> 3.1.3'
gem 'formtastic-bootstrap', '~> 3.1.1'

if ENV['API_DEV']
  gem 'gds-api-adapters', path: '../gds-api-adapters'
else
  gem 'gds-api-adapters', '~> 52.8.0'
end

gem "govuk_app_config", "~> 1.8.0"
