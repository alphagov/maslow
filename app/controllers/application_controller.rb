class ApplicationController < ActionController::Base
  protect_from_forgery
  check_authorization

  rescue_from ActionController::InvalidAuthenticityToken do
    render plain: "Invalid authenticity token", status: :forbidden
  end

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to needs_path, alert: "You do not have permission to perform this action."
  end

  include GDS::SSO::ControllerMethods

  before_action :authenticate_user!

private

  def verify_authenticity_token
    raise ActionController::InvalidAuthenticityToken unless verified_request?
  end
end
