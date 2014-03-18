require 'gds_api/need_api'
require 'plek'
require 'json'

class NotesController < ApplicationController
  def create
    authorize! :create, Note
    text = params["notes"]["text"]
    need_id = params["need_id"]
    @note = Note.new(text, need_id, current_user)

    if @note.save
      flash[:notice] = "Note saved"
    else
      flash[:error] = "Note couldn't be saved: #{@note.errors}"
    end
    redirect_to revisions_need_path(need_id)
  end
end
