require 'gds_api/need_api'

desc "Clean the notes imported from the Need API"
task clean_notes_data: :environment do
  Note.each do |n|
    begin
      # Change Need IDs into content_ids.
      n.content_id = Maslow.need_api.content_id(n.need_id)
      puts "Need ID #{n.need_id} => Content ID #{n.content_id}"
      n.save
    rescue GdsApi::HTTPNotFound
      n.content_id = nil
    end
  end
end
