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
    authorize! :index, Need
    opts = params.slice("organisation_id", "page", "q").select { |k, v| v.present? }

    @bookmarks = current_user.bookmarks
    @current_page = needs_path

    @needs = Need.list(opts)
    respond_to do |format|
      format.html
      format.csv do
        send_data NeedsCsvPresenter.new(needs_url, @needs.map{|n| Need.find(n.id)}).to_csv,
                  filename: "#{params["organisation_id"]}.csv",
                  type: "text/csv; charset=utf-8"
      end
    end
  end

  def show
    authorize! :read, Need
    @need = load_need
  end

  def actions
    authorize! :perform_actions_on, Need
    @need = load_need
  end

  def revisions
    authorize! :see_revisions_of, Need
    @need = load_need
  end

  def edit
    authorize! :update, Need
    @need = load_need
    if @need.duplicate?
      redirect_to need_url(@need.need_id),
                  notice: "Closed needs cannot be edited",
                  status: 303
      return
    end
  end

  def new
    authorize! :create, Need
    @need = Need.new({})
  end

  def create
    authorize! :create, Need
    @need = Need.new( prepare_need_params(params) )

    add_or_remove_criteria(:new) and return if criteria_params_present?

    if @need.valid?
      if @need.save_as(current_user)
        redirect_to redirect_url, notice: "Need created",
          flash: { need_id: @need.need_id, goal: @need.goal }
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
    authorize! :update, Need
    @need = load_need
    @need.update(prepare_need_params(params))

    add_or_remove_criteria(:edit) and return if criteria_params_present?

    if @need.valid?
      if @need.save_as(current_user)
        redirect_to redirect_url, notice: "Need updated",
          flash: { need_id: @need.need_id, goal: @need.goal }
        return
      else
        flash[:error] = "There was a problem saving your need."
      end
    else
      flash[:error] = "There were errors in the need form."
    end

    render "edit", :status => 422
  end

  def close_as_duplicate
    authorize! :close, Need
    @need = load_need
    if @need.duplicate?
      redirect_to need_url(@need.need_id),
                  notice: "This need is already closed",
                  status: 303
      return
    end
  end

  def closed
    authorize! :close, Need
    @need = load_need
    @need.duplicate_of = Integer(params["need"]["duplicate_of"])

    if @need.valid?
      if @need.close_as(current_user)
        @canonical_need = Need.find(@need.duplicate_of)
        redirect_to need_url(@need.need_id), notice: "Need closed as a duplicate of",
          flash: { need_id: @canonical_need.need_id, goal: @canonical_need.goal }
        return
      else
        flash[:error] = "There was a problem closing the need as a duplicate"
      end
    else
      flash[:error] = "The Need ID entered is invalid"
    end

    @need.duplicate_of = nil
    render "actions", :status => 422
  end

  def reopen
    authorize! :reopen, Need
    @need = load_need
    old_canonical_id = @need.duplicate_of

    if @need.reopen_as(current_user)
      redirect_to need_url(@need.need_id), notice: "Need is no longer a duplicate of",
        flash: { need_id: old_canonical_id, goal: Need.find(old_canonical_id).goal }
      return
    else
      flash[:error] = "There was a problem reopening the need"
    end

    render "show", :status => 422
  end

  def out_of_scope
    authorize! :descope, Need
    @need = load_need
    unless @need.in_scope.nil?
      flash[:error] = "This need has already been marked as out of scope"
      redirect_to need_path(@need)
      return
    end
  end

  def descope
    authorize! :descope, Need
    @need = load_need

    unless @need.in_scope.nil?
      flash[:error] = "This need has already been marked as out of scope"
      redirect_to need_path(@need)
      return
    end

    if params["need"]["out_of_scope_reason"].blank?
      flash[:error] = "A reason is required to mark a need as out of scope"
      redirect_to need_path(@need)
      return
    end

    @need.in_scope = false
    @need.out_of_scope_reason = params["need"]["out_of_scope_reason"]

    if @need.save_as(current_user)
      flash[:need_id] = @need.need_id
      flash[:goal] = @need.goal
      flash[:notice] = "Need has been marked as out of scope"
    else
      flash[:error] = "We had a problem marking the need as out of scope"
    end

    redirect_to need_path(@need)
  end

  private

  def redirect_url
    params["add_new"] ? new_need_path : need_url(@need.need_id)
  end

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
