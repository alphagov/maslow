source 'https://rubygems.org'

gem 'rails', '~> 4.0'

gem 'mongoid', '4.0.2'
gem 'plek', '~> 1.11.0'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '~> 11.0'
end

gem 'kaminari', '0.16.3'
gem 'logstasher', '0.4.8'
gem 'airbrake', '~> 4.3'
gem 'cancan', '1.6.10'
gem 'lrucache', '0.1.4'

group :test do
  gem 'pry-byebug'
  gem 'webmock', '1.22.1'
  gem 'test-unit'
  gem 'capybara', '2.5.0'
  # https://github.com/DatabaseCleaner/database_cleaner/issues/299
  gem 'database_cleaner', '1.4.1', require: false
  gem 'factory_girl_rails', '4.5.0'
  gem 'shoulda-context', '1.2.1'
  gem 'mocha', '1.1.0', require: false
  gem 'timecop', '0.8.0'
end

group :development, :test do
  gem 'govuk-lint'
  gem 'jasmine', '2.3.1'
end

gem 'sass-rails', '~> 5.0.3'
gem 'uglifier', '2.7.1'

gem 'chosen-rails'

gem 'govuk_admin_template', '3.0.0'
gem 'unicorn'
gem 'formtastic', '3.1.3'
gem 'formtastic-bootstrap', '3.1.1'

if ENV['API_DEV']
  gem 'gds-api-adapters', path: '../gds-api-adapters'
else
  gem 'gds-api-adapters', '~> 38.1'
end
