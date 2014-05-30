source 'https://rubygems.org'

gem 'rails', '3.2.17'

gem 'mongoid', '3.0.23'
gem 'plek', '1.4.0'
gem 'aws-ses', :require => 'aws/ses'

if ENV['SSO_DEV']
  gem 'gds-sso', path: '../gds-sso'
else
  gem 'gds-sso', '9.2.2'
end

gem 'kaminari', '0.14.1'
gem 'logstasher', '0.4.8'
gem 'cancan', '1.6.10'

group :test do
  gem 'capybara', '2.1.0'
  gem 'database_cleaner', '1.1.1', require: false
  gem 'factory_girl_rails', '4.2.1'
  gem 'shoulda-context', '1.1.5'
  gem 'simplecov', '0.7.1'
  gem 'simplecov-rcov'
  gem 'mocha', '0.14.0', require: false
  gem 'webmock', '1.14.0'
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  gem 'uglifier', '>= 1.0.3'
end

gem 'chosen-rails'

gem 'govuk_admin_template', '0.0.5'
gem 'unicorn'
gem 'exception_notification', '2.6.1'
gem 'formtastic', '2.3.0.rc3'
gem 'formtastic-bootstrap', '3.0.0'

if ENV['API_DEV']
  gem 'gds-api-adapters', path: '../gds-api-adapters'
else
  gem 'gds-api-adapters', '10.6.3'
end
