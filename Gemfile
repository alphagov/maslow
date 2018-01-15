source 'https://rubygems.org'

gem 'rails', '~> 5.0.2'

gem 'mongoid', '6.1.1'
gem 'plek', '~> 2.0.0'
gem 'govspeak', '~> 5'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '~> 13.5'
end

gem 'kaminari', '1.1.1'
gem 'logstasher', '1.2.2'
gem 'cancancan', '2.1.2'
gem 'lrucache', '0.1.4'

group :test do
  gem 'pry-byebug'
  gem 'webmock', '~> 2.3.0'
  gem 'test-unit'
  gem 'capybara', '2.16.1'
  gem 'database_cleaner', '1.6.2', require: false
  gem 'factory_girl_rails', '4.9.0'
  gem 'rails-controller-testing', '1.0.2'
  gem 'shoulda-context', '1.2.2'
  gem 'mocha', '1.1.0', require: false
  gem 'timecop', '0.9.1'
end

group :development, :test do
  gem 'govuk-lint'
  gem 'jasmine', '2.8.0'
end

gem 'sass-rails', '~> 5.0.3'
gem 'uglifier', '2.7.1'

gem 'chosen-rails'

gem 'govuk_admin_template', '6.4.0'
gem 'unicorn'
gem 'formtastic', '~> 3.1.3'
gem 'formtastic-bootstrap', '~> 3.1.1'

if ENV['API_DEV']
  gem 'gds-api-adapters', path: '../gds-api-adapters'
else
  gem 'gds-api-adapters', '~> 51.0.0'
end

gem "govuk_app_config", "~> 0.2.0"
