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
    if params_hash["need"]
      # Remove empty strings from multi-valued fields that Rails inserts.
      ["justifications","organisation_ids"].each do |field|
        if params_hash["need"][field]
          params_hash["need"][field].select!(&:present?)
        end
      end
      # Convert free text into List of sentences
      ["met_when","legislation"].each do |field|
        if params_hash["need"][field]
          params_hash["need"][field] = params_hash["need"][field].split("\n").map(&:strip)
        end
      end
    end
    params_hash["need"]
  end
end
