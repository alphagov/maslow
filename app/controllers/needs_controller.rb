require 'gds_api/need_api'
require 'plek'
require 'json'

class NeedsController < ApplicationController

  def index
  end

  def new
    @need = Need.new({})
  end

  def create
    # Rails inserts an empty string into multi-valued fields.
    # We are removing the unneeded value
    if params["need"]
      if params["need"]["justifications"]
        params["need"]["justifications"].select!(&:present?)
      end
      if params["need"]["organisation_ids"]
        params["need"]["organisation_ids"].select!(&:present?)
      end
      if params["need"]["met_when"]
        params["need"]["met_when"] = params["need"]["met_when"].split("\n").map(&:strip)
      end
    end
    @need = Need.new(params["need"])

    if @need.valid?
      @need.save
      redirect_to("/")
    else
      @need.met_when = @need.met_when.try do |f|
        f.join("\n")
      end
      render "new"
    end
  end

end
