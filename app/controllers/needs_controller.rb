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
    flash.keep
    @need = load_need
    redirect_to :action => :edit, :id => params[:id]
  end

  def edit
    @need = load_need
    @target = need_path(params[:id])

    # edit.html.erb
  end

  def new
    @need = Need.new({})
    @target = needs_path

    # new.html.erb
  end

  def create
    @need = Need.new( prepare_need_params(params) )

    add_criteria(:new) and return if params[:criteria_action]
    remove_criteria(:new) and return if remove_criteria_selected?

    if @need.valid?
      if @need.save_as(current_user)
        redirect_to "/needs", notice: "Need created."
        return
      else
        flash[:error] = "There was a problem saving your need."
      end
    else
      flash[:error] = "Please fill in the required fields."
    end

    render "new", :status => 422
  end

  def update
    @need = load_need
    @need.update(prepare_need_params(params))

    add_criteria(:edit) and return if params[:criteria_action]
    remove_criteria(:edit) and return if remove_criteria_selected?

    if @need.valid?
      if @need.save_as(current_user)
        redirect_to need_url(@need.need_id), notice: "Need updated."
        return
      else
        flash[:error] = "There was a problem saving your need."
      end
    else
      flash[:error] = "There were errors in the need form."
    end

    @target = need_path(params[:id])
    render "edit", :status => 422
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
    end
    params_hash["need"]
  end

private

  def load_need
    begin
      need_id = Integer(params[:id])
      Need.find(need_id)
    rescue ArgumentError, TypeError # shouldn't happen; route is constrained
      raise Http404
    rescue Need::NotFound
      raise Http404
    end
  end

  def add_criteria(action)
    @need.add_more_criteria
    render :action => action
  end

  def remove_criteria_selected?
    key = params.keys.select { |k| k.include? "delete_criteria" }
    if key.present?
      @delete_criteria = Integer(key.first.split("_").last)
    else
      return false
    end
    true
  rescue ArgumentError
    # there was a key but it's value was invalid.
    true
  end

  def remove_criteria(action)
    @need.remove_criteria(@delete_criteria) if @delete_criteria
    render :action => action
  end
end
