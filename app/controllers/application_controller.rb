class ApplicationController < ActionController::Base
  protect_from_forgery

  include GDS::SSO::ControllerMethods

  before_filter :authenticate_user!
  before_filter :require_signin_permission!
  before_filter :set_frame_options

  private

  def set_frame_options
    headers["X-Frame-Options"] = "SAMEORIGIN"
  end
end
