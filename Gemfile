source 'https://rubygems.org'

gem 'rails', '3.2.14'

gem 'mongoid', '3.0.23'
gem 'plek', '1.4.0'
gem 'aws-ses', :require => 'aws/ses'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '3.1.0'
end

group :test do
  gem 'capybara', '2.1.0'
  gem 'database_cleaner', '1.1.1', require: false
  gem 'factory_girl_rails', '4.2.1'
  gem 'shoulda-context', '1.1.5'
  gem 'simplecov', '0.7.1'
  gem 'simplecov-rcov'
  gem 'mocha', '0.14.0', require: false
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

gem 'unicorn'
gem 'exception_notification', '2.6.1'
gem 'bootstrap-sass', '2.3.2.2'
gem 'formtastic', '2.2.1'
gem 'formtastic-bootstrap', '2.1.3'
gem 'gds-api-adapters', '7.8.0'
gem 'webmock', '1.14.0'
