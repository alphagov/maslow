require_relative "../test_helper"

class NoteTest < ActiveSupport::TestCase
  setup do
    @author = {
      name: "Winston Smith-Churchill",
      email: "winston@alphagov.co.uk",
      uid: "win5t0n",
    }
  end

  should "save note data to the database" do
    Note.new(
      "text" => "test",
      "need_id" => "100001",
      "content_id" => "123abc",
      "author" => @author,
    ).save
  end

  should "have errors set if the note couldn't be saved" do
    note = Note.new(
      "text" => "",
      "need_id" => "100001",
      "content_id" => "123abc",
      "author" => @author,
    )
    assert_equal false, note.valid?

    assert_equal "Text can't be blank", note.errors.full_messages.first
  end
end
