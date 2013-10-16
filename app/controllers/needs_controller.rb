require 'gds_api/need_api'
require 'plek'
require 'json'

class NeedsController < ApplicationController

  def index
    @needs = Maslow.need_api.needs
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
      render "new"
    end
  end

  private

  def prepare_need_params(params_hash)
    # Rails inserts an empty string into multi-valued fields.
    # We are removing the unneeded value
    if params_hash["need"]
      if params_hash["need"]["justifications"]
        params_hash["need"]["justifications"].select!(&:present?)
      end
      if params_hash["need"]["organisation_ids"]
        params_hash["need"]["organisation_ids"].select!(&:present?)
      end
      if params_hash["need"]["met_when"]
        params_hash["need"]["met_when"] = params_hash["need"]["met_when"].split("\n").map(&:strip)
      end
    end
    params_hash["need"]
  end
end
