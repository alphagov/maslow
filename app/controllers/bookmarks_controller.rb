class BookmarksController < ApplicationController

  def bookmarks
    @bookmarks = current_user.bookmarks
    @needs = @bookmarks.map do |need_id|
      Need.find(need_id)
    end
    @current_page = bookmarks_path
  end

  def bookmark
    need_id = Integer(params["bookmark"]["need_id"])
    @bookmarks = current_user.bookmarks
    if @bookmarks.include?(need_id)
      @bookmarks.delete(need_id)
    else
      @bookmarks << need_id
    end
    current_user.save!
    redirect_to params["bookmark"]["redirect_to"]
  end
end
