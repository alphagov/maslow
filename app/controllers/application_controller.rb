class ApplicationController < ActionController::Base
  protect_from_forgery

  include GDS::SSO::ControllerMethods

  before_filter :authenticate_user!
  before_filter :require_signin_permission!
end
