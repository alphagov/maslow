require 'gds_api/need_api'
require 'plek'
require 'json'

class NeedsController < ApplicationController

  def index
    opts = {}
    opts = params.slice("organisation_id")
    @needs = Maslow.need_api.needs(opts)
  end

  def new
    @need = Need.new({})
  end

  def create
    @need = Need.new( prepare_need_params(params) )

    if @need.valid?
      @need.save
      redirect_to "/needs", notice: "Need created."
    else
      @need.met_when = @need.met_when.try do |f|
        f.join("\n")
      end
      flash[:error] = "Please fill in the required fields."
      render "new", :status => 422
    end
  end

  private

  def prepare_need_params(params_hash)
    if params_hash["need"]
      # Remove empty strings from multi-valued fields that Rails inserts.
      ["justifications","organisation_ids"].each do |field|
        if params_hash["need"][field]
          params_hash["need"][field].select!(&:present?)
        end
      end
      # Convert free text into List of sentences
      if params_hash["need"]["met_when"]
        params_hash["need"]["met_when"] = params_hash["need"]["met_when"].split("\n").map(&:strip)
      end
    end
    params_hash["need"]
  end
end
