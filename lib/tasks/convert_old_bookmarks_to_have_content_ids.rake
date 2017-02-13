require 'gds_api/need_api'

desc "Convert old-style bookmarks (with need_ids) to use content_ids"
task convert_bookmarks_from_need_ids_to_content_ids: :environment do
  User.all.each do |u|
    u.bookmarks.each do |bookmark|
      if bookmark.size <= 10
        need_id = bookmark
        content_id = Maslow.need_api.content_id(need_id)

        u.bookmarks << content_id
        u.bookmarks.delete(need_id)
        u.save

        puts "Reassigned bookmark ID #{need_id} to #{content_id}."
      else
        puts "Bookmark was already a content ID!"
      end
    end
  end
end
