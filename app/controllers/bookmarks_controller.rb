class BookmarksController < ApplicationController
  def index
    authorize! :index, :bookmark

    @bookmarks = current_user.bookmarks
    @needs = @bookmarks.map do |need_id|
      Need.find(need_id)
    end
    @current_page = bookmarks_path
  end

  def toggle
    authorize! :create, :bookmark

    need_id = params["bookmark"]["need_id"]
    current_user.toggle_bookmark(need_id.to_i)
    current_user.save!

    redirect_to params["bookmark"]["redirect_to"]
  end
end
