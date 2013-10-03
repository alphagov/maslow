require "need_api_submitter"

class NeedsController < ApplicationController

  def need_api_submitter
    NeedAPISubmitter.instance
  end

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
    if params["need"]
      if params["need"]["justification"]
        params["need"]["justification"].select!(&:present?)
      end
      if params["need"]["met_when"]
        params["need"]["met_when"] = params["need"]["met_when"].split("\n").map(&:strip)
      end
    else
      raise(ArgumentError, "Need data not found")
    end
    @need = Need.new(params["need"])

    if @need.valid?
      need_api_submitter.create(@need)
      redirect_to("/")
    else
      render "new", :status => :unprocessable_entity
    end
  end
end
