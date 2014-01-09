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
    opts = params.slice("organisation_id", "page", "q").select { |k, v| v.present? }
    @needs = Maslow.need_api.needs(opts)
  end

  def export
    opts = params.slice("organisation_id").select { |k, v| v.present? }
    @needs = Maslow.need_api.needs(opts).to_a
    result_csv = CSV.generate do |csv|
      csv << ["Role", "Goal", "Benefit"]
      @needs.each do |n|
        csv << [n.role, n.goal, n.benefit]
      end
    end
    send_data result_csv
  end

  def show
    @need = load_need

    # show.html.erb
  end

  def revisions
    @need = load_need

    # revisions.html.erb
  end

  def edit
    @need = load_need
    if @need.duplicate_of.present?
      redirect_to need_url(@need.need_id),
                  notice: "Closed needs cannot be edited",
                  status: 303
      return
    end
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

    add_or_remove_criteria(:new) and return if criteria_params_present?

    if @need.valid?
      if @need.save_as(current_user)
        redirect_to need_url(@need.need_id), notice: "Need created."
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

    add_or_remove_criteria(:edit) and return if criteria_params_present?

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

  def closed
    main_need_id = prepare_need_params(params)["duplicate_of"]
    @need = load_need
    @need.duplicate_of = main_need_id

    if @need.valid?
      if @need.close_as(current_user)
        redirect_to need_url(@need.need_id), notice: "Need closed as a duplicate of #{main_need_id}"
        return
      else
        flash[:error] = "There was a problem closing the need as a duplicate"
      end
    else
      flash[:error] = "The Need ID entered is invalid"
    end

    @target = need_path(params[:id])
    render "edit", :status => 422
  end

  def descope
    @need = load_need

    unless @need.in_scope.nil?
      flash[:error] = "This need has already been marked as out of scope"
      redirect_to need_path(@need)
      return
    end

    @need.in_scope = false

    if @need.save_as(current_user)
      flash[:notice] = "Need has been marked as out of scope"
    else
      flash[:error] = "We had a problem marking the need as out of scope"
    end

    redirect_to need_path(@need)
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

  def criteria_params_present?
    params[:criteria_action].present? || params[:delete_criteria].present?
  end

  def add_or_remove_criteria(action)
    add_criteria if params[:criteria_action]
    remove_criteria if params[:delete_criteria]
    render :action => action
  end

  def add_criteria
    @need.add_more_criteria
  end

  def remove_criteria
    index = Integer(params[:delete_criteria])
    @need.remove_criteria(index)
  rescue ArgumentError
  end
end
