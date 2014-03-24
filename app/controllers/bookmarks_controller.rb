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

    need_id = params["bookmark"]["need_id"].to_i
    if need_id > 0
      current_user.toggle_bookmark(need_id)
      current_user.save!
    else
      flash[:error] = "Cannot bookmark invalid need id"
    end

    redirect_to whitelist_redirect_to
  end

  private

  def whitelist_redirect_to
    path = params["bookmark"]["redirect_to"]
    if ["/needs","/bookmarks"].include?(path)
      path
    else
      "/needs"
    end
  end
end
