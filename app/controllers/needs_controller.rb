require "plek"
require "json"

class NeedsController < ApplicationController
  class Http404 < StandardError
  end

  rescue_from Http404 do
    render file: Rails.root.join("public/404.html"), status: :not_found
  end

  def index
    authorize! :index, Need
    opts = params.permit(
      "page", "q", "organisation_id"
    ).slice("page", "q", "organisation_id").select { |_k, v| v.present? }.to_h

    @bookmarks = current_user.bookmarks
    @current_page = needs_path

    @needs = Need.list(opts)
    respond_to do |format|
      format.html
      format.csv do
        send_data NeedsCsvPresenter.new(needs_url, @needs).to_csv,
                  filename: "needs.csv",
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
    return if request.get?

    case params["need_action"]
    when "publish"
      publish
    when "unpublish"
      unpublish
    when "discard"
      discard
    else
      flash[:error] = "Unknown action: #{params['need_action']}"
      render "actions", status: :unprocessable_entity
    end
  end

  def revisions
    authorize! :see_revisions_of, Need
    @need = load_need
    @notes = load_notes_for_need
    @revisions_and_notes = (@need.revisions + @notes).sort_by do |x|
      # Either a Hash or a Note, so transform the `updated_at`s into
      # the same type.
      x.try(:updated_at) || Time.zone.parse(x["updated_at"])
    end
    # `.sort_by` doesn't take "asc" or "desc" options, so sort in descending
    # order by reversing the array.
    @revisions_and_notes.reverse!
  end

  def edit
    authorize! :update, Need
    @need = load_need
    if @need.unpublished?
      redirect_to need_url(@need.content_id),
                  notice: "Closed needs cannot be edited",
                  status: :see_other
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
      if @need.save!
        redirect_to redirect_url,
                    notice: "Need created",
                    flash: { goal: @need.goal }
      else
        flash[:error] = "There was a problem saving your need."
        render "new", status: :internal_server_error
      end
    else
      flash[:error] = "Please fill in the required fields."
      render "new", status: :unprocessable_entity
    end
  rescue Need::BasePathAlreadyInUse => e
    logger.error("content_id: #{e.content_id}")

    flash[:error] = true
    flash[:base_path_already_in_use] = e.content_id
    render "new", status: :unprocessable_entity
  end

  def update
    authorize! :update, Need
    @need = load_need
    @need.set_attributes(need_params)

    if criteria_params_present?
      add_or_remove_criteria(:edit)
      return
    end

    if @need.valid?
      if @need.save! && (@need.draft? || @need.publish)
        redirect_to redirect_url,
                    notice: "Need updated",
                    flash: { need_id: @need.need_id, goal: @need.goal }
      else
        flash[:error] = "There was a problem saving your need."
        render "edit", status: :internal_server_error
      end
    else
      flash[:error] = "There were errors in the need form."
      render "edit", status: :unprocessable_entity
    end
  rescue Need::BasePathAlreadyInUse => e
    logger.error("content_id: #{e.content_id}")

    flash[:error] = true
    flash[:base_path_already_in_use] = e.content_id
    render "new", status: :unprocessable_entity
  end

private

  def publish
    authorize! :publish, Need

    if @need.publish
      redirect_to need_path(@need.content_id)
    else
      flash[:error] = "A problem was encountered when publishing"
      render status: :internal_server_error
    end
  end

  def discard
    authorize! :publish, Need
    @need = load_need

    if @need.discard
      redirect_to(
        needs_path,
        notice: "Need discarded",
      )
    else
      flash[:error] = "A problem was encountered when publishing"
      render status: :internal_server_error
    end
  end

  def unpublish
    authorize! :unpublish, Need

    explanation = nil

    if params.key? "duplicate_of"
      duplicate_content_id = params["duplicate_of"]

      if duplicate_content_id == @need.content_id
        flash[:error] = "Need cannot be a duplicate of itself"
        render status: :unprocessable_entity
        return
      end

      begin
        # Check the need exists
        Need.find(duplicate_content_id)
      rescue Need::NotFound
        flash[:error] = "Duplicate need not found"
        render status: :unprocessable_entity
        return
      end

      explanation = "This need is a duplicate of: [embed:link:#{params['duplicate_of']}]"
    else
      explanation = params["explanation"]
    end

    if @need.unpublish(explanation)
      redirect_to(
        need_path(@need.content_id),
        notice: "Need withdrawn",
      )
    else
      flash[:error] = "There was a problem updating the need’s status"
      render status: :internal_server_error
    end
  end

  def redirect_url
    params["add_new"] ? new_need_path : need_url(@need.content_id)
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
      cleaned_params[:met_when].delete_if(&:empty?) if cleaned_params.key? :met_when

      %w[justifications organisation_ids].each do |field|
        cleaned_params[field].select!(&:present?) if cleaned_params[field]
      end
    end
  end

  def load_need
    Need.find(params[:content_id])
  rescue Need::NotFound
    raise Http404
  end

  def load_notes_for_need
    Note.where(content_id: params[:content_id]).to_a
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
  rescue ArgumentError # rubocop:disable Lint/SuppressedException
  end
end
