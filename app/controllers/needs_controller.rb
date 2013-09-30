class NeedsController < ApplicationController
  def index
  end

  def new
    @why_needed = ["legislation", "obligation", "other"]
  end

  def create
    redirect_to("/")
  end
end
