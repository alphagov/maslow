source 'https://rubygems.org'

gem 'rails', '4.2.4'

gem 'mongoid', '4.0.2'
gem 'plek', '1.4.0'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '9.3.0'
end

gem 'kaminari', '0.14.1'
gem 'logstasher', '0.4.8'
gem 'airbrake', '~> 4.0.0'
gem 'cancan', '1.6.10'
gem 'lrucache', '0.1.4'

group :test do
  gem 'pry-byebug'
  gem 'webmock', '1.22.1'
  gem 'test-unit'
  gem 'capybara', '2.5.0'
  gem 'database_cleaner', '1.1.1', require: false
  gem 'factory_girl_rails', '4.2.1'
  gem 'shoulda-context', '1.2.1'
  gem 'simplecov', '0.7.1'
  gem 'simplecov-rcov'
  gem 'mocha', '0.14.0', require: false
  gem 'timecop', '0.7.1'
end

group :development, :test do
  gem 'jasmine', '2.1.0'
end

gem 'sass-rails',   '~> 5.0.3'
gem 'uglifier', '2.7.1'

gem 'chosen-rails'

gem 'govuk_admin_template', '3.0.0'
gem 'unicorn'
gem 'formtastic', '2.3.0'
gem 'formtastic-bootstrap', '3.0.0'

if ENV['API_DEV']
  gem 'gds-api-adapters', path: '../gds-api-adapters'
else
  gem 'gds-api-adapters', '20.1.1'
end
