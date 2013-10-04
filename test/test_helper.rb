ENV["RAILS_ENV"] = "test"

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner'

require 'simplecov'
require 'simplecov-rcov'

require 'mocha/setup'

require 'webmock/test_unit'

SimpleCov.start 'rails'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean

class ActiveSupport::TestCase
  teardown do
    DatabaseCleaner.clean
  end

  def stub_user
    @stub_user ||= FactoryGirl.create(:user, :name => 'Stub User')
  end

  def login_as_stub_user
    login_as stub_user
  end

  def login_as(user)
    request.env['warden'] = stub(
      :authenticate! => true,
      :authenticated? => true,
      :user => user
    )
  end
end
