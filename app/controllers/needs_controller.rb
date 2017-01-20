require 'gds_api/need_api'
require 'plek'
require 'json'

class NeedsController < ApplicationController
  class Http404 < StandardError
  end

  rescue_from Http404 do
    render file: "public/404", status: :not_found
  end

  def index
    authorize! :index, Need
    opts = params.slice("organisation_id", "page", "q").select { |_k, v| v.present? }

    @bookmarks = current_user.bookmarks
    @current_page = needs_path

    @needs = Need.list(opts)
    respond_to do |format|
      format.html
      format.csv do
        send_data NeedsCsvPresenter.new(needs_url, @needs).to_csv,
                  filename: "#{params['organisation_id']}.csv",
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
    @notes = load_notes_for_need
    @revisions_and_notes = (@need.revisions + @notes).sort_by do |x|
      # Either a Hash or a Note, so transform the `created_at`s into
      # the same type.
      x.try(:created_at) || Time.zone.parse(x["created_at"])
    end
    # `.sort_by` doesn't take "asc" or "desc" options, so sort in descending
    # order by reversing the array.
    @revisions_and_notes.reverse!
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

    @need = Need.new(need_params)
    if criteria_params_present?
      add_or_remove_criteria(:new)
      return
    end


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

    render "new", status: 422
  rescue Need::BasePathAlreadyInUse => err
    logger.error("content_id: #{err.content_id}")

    flash[:error] = true
    flash[:base_path_already_in_use] = err.content_id
    render "new", status: 422
  end

  def update
    authorize! :update, Need
    @need = load_need
    @need.update(need_params)

    if criteria_params_present?
      add_or_remove_criteria(:edit)
      return
    end

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

    render "edit", status: 422
  rescue Need::BasePathAlreadyInUse => err
    logger.error("content_id: #{err.content_id}")

    flash[:error] = true
    flash[:base_path_already_in_use] = err.content_id
    render "new", status: 422
  end

  def closed
    authorize! :close, Need
    @need = load_need
    duplicate_of = params["duplicate_of"]

    if @need.close_as_duplicate_of(duplicate_of, current_user)
      @canonical_need = Need.find(duplicate_of)
      redirect_to(
        need_url(@need.content_id),
        notice: "Need closed as a duplicate of",
        flash: { content_id: duplicate_of, goal: @canonical_need.goal }
      )
    else
      flash[:error] = "There was a problem closing the need as a duplicate"
      render "actions", status: 422
    end
  end

  def reopen
    authorize! :reopen, Need
    @need = load_need

    if @need.save_as(current_user)
      redirect_to(
        need_url(@need.need_id),
        notice: "Need is no longer marked as a duplicate",
      )
      return
    else
      flash[:error] = "There was a problem reopening the need"
    end

    render "show", status: 422
  end

  def status
    authorize! :validate, Need
    @need = load_need
  end

  def update_status
    authorize! :validate, Need
    @need = load_need

    need_status = NeedStatus.new(need_status_params)

    unless need_status.valid?
      flash[:error] = need_status.errors.full_messages.join(". ")
      redirect_to need_path(@need)
      return
    end

    @need.status = need_status.as_json

    unless @need.save_as(current_user)
      flash[:error] = "We had a problem updating the need’s status"
    end

    redirect_to need_path(@need)
  end

  private

  def redirect_url
    params["add_new"] ? new_need_path : need_url(@need.need_id)
  end

  def need_status_params
    filtered = params.require(:need)
      .require(:status)
      .permit(
        :description,
        :additional_comments,
        :validation_conditions,
        :other_reasons_why_invalid,
        common_reasons_why_invalid: [],
      )

    {
      description: filtered[:description],
      reasons: [
        filtered[:common_reasons_why_invalid],
        filtered[:other_reasons_why_invalid],
      ].flatten.select(&:present?),
      additional_comments: filtered[:additional_comments],
      validation_conditions: filtered[:validation_conditions],
    }
  end

  def need_params
    params.require(:need).permit(
      :role,
      :goal,
      :benefit,
      :legislation,
      :yearly_user_contacts,
      :yearly_need_views,
      :yearly_site_views,
      :yearly_searches,
      :other_evidence,
      :impact,
      organisation_ids: [],
      justifications: [],
      met_when: [],
    ).tap do |cleaned_params|
      cleaned_params[:met_when].delete_if(&:empty?)

      %w(justifications organisation_ids).each do |field|
        cleaned_params[field].select!(&:present?) if cleaned_params[field]
      end
    end
  end

  def load_need
    begin
      Need.find(params[:content_id])
    rescue ArgumentError, TypeError # shouldn't happen; route is constrained
      raise Http404
    rescue Need::NotFound
      raise Http404
    end
  end

  def load_notes_for_need
    need_id = Integer(params[:id])
    Note.where(need_id: need_id).to_a
  end

  def criteria_params_present?
    params[:criteria_action].present? || params[:delete_criteria].present?
  end

  def add_or_remove_criteria(action)
    add_criteria if params[:criteria_action]
    remove_criteria if params[:delete_criteria]
    render action: action
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
