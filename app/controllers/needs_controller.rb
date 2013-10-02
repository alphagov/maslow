class NeedsController < ApplicationController
  def index
  end

  def new
    @need = Need.new({})
    @justification = ["legislation", "obligation", "other"]
    @impacts = [
      "Endangers the health of individuals",
      "Has serious consequences for the day-to-day lives of your users",
      "Annoys the majority of your users. May incur fines",
      "Noticed by the average member of the public",
      "Noticed by an expert audience",
      "No impact"
    ]
  end

  def create
    # Rails inserts an empty string into multi-valued fields.
    # We are removing the unneeded value
    if params["need"] && params["need"]["justification"]
      params["need"]["justification"].select!(&:present?)
    end
    @need = Need.new(params["need"])
    redirect_to("/")
  end
end
