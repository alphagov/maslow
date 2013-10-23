require 'gds_api/need_api'
require 'plek'
require 'json'

class NeedsController < ApplicationController

  class Http404 < StandardError
  end

  rescue_from Http404 do
    render "public/404", :status => 404
  end

  def index
    opts = params.slice("organisation_id")
    @needs = Maslow.need_api.needs(opts)
  end

  def show
    redirect_to :action => :edit, :id => params[:id]
  end

  def edit
    begin
      need_id = Integer(params[:id])
      @need = Need.find(need_id)
    rescue ArgumentError, TypeError # shouldn't happen; route is constrained
      raise Http404
    rescue Need::NotFound
      raise Http404
    end

    @target = need_path(need_id)
    render "new"
  end

  def new
    @need = Need.new({})
    @target = needs_path
  end

  def create
    @need = Need.new( prepare_need_params(params) )

    if @need.valid?
      @need.save_as(current_user)
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
