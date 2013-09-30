class NeedsController < ApplicationController
  def index
  end

  def new
    @why_needed = ["legislation", "obligation", "other"]
  end
end
