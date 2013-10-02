class NeedsController < ApplicationController
  def index
  end

  def new
    @why_needed = ["legislation", "obligation", "other"]
    @impacts = ["Ben's impact #1", "Ben's impact #2", "Ben's impact #3"]
  end

  def create
    redirect_to("/")
  end
end
