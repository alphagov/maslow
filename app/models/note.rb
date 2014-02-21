class Note

  attr_reader :text, :need_id, :author

  def initialize(text, need_id, author)
    @text = text
    @need_id = need_id
    @author = author
  end

  def save
    note_atts = {
      "text" => text,
      "need_id" => need_id,
      "author" => author_atts(author)
    }
    Maslow.need_api.create_note(note_atts)
    true
  rescue GdsApi::HTTPErrorResponse => err
    false
  end

  private

  def author_atts(author)
    {
      "name" => author.name,
      "email" => author.email,
      "uid" => author.uid
    }
  end
end
