class ApplicationController < ActionController::Base
  protect_from_forgery
  check_authorization

  rescue_from ActionController::InvalidAuthenticityToken do
    render text: "Invalid authenticity token", status: 403
  end

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to needs_path, alert: "You do not have permission to perform this action."
  end

  include GDS::SSO::ControllerMethods

  before_filter :authenticate_user!
  before_filter :require_signin_permission!

  private
  def verify_authenticity_token
    raise ActionController::InvalidAuthenticityToken unless verified_request?
  end
end
