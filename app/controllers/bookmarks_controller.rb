class BookmarksController < ApplicationController
  def index
    authorize! :index, :bookmark

    @bookmarks = current_user.bookmarks
    @needs = @bookmarks.any? ? Need.by_content_ids(@bookmarks) : []
    @current_page = bookmarks_path
  end

  def toggle
    authorize! :create, :bookmark

    content_id = params["bookmark"]["content_id"]
    current_user.toggle_bookmark(content_id)
    current_user.save!

    redirect_to whitelist_redirect_to
  end

  private

  def whitelist_redirect_to
    path = params["bookmark"]["redirect_to"]
    if ["/needs", "/bookmarks"].include?(path)
      path
    else
      "/needs"
    end
  end
end
