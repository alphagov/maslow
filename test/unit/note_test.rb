require_relative '../test_helper'
require 'gds_api/test_helpers/need_api'

class NoteTest < ActiveSupport::TestCase
  include GdsApi::TestHelpers::NeedApi

  setup do
    @author = OpenStruct.new(
      name: "Winston Smith-Churchill",
      email: "winston@alphagov.co.uk",
      uid: "win5t0n"
    )
  end

  should "send note data to the need api" do
    stub_create_note(
      "text" => "test",
      "need_id" => "100001",
      "author" => {
        "name" => "Winston Smith-Churchill",
        "email" => "winston@alphagov.co.uk",
        "uid" => "win5t0n"
      }
    )

    Note.new("test", "100001", @author).save
  end

  should "have errors set if the note couldn't be saved" do
    GdsApi::NeedApi.any_instance.expects(:create_note).raises(
      GdsApi::HTTPErrorResponse.new(422, "invalid note", {"errors" => ["error"]})
    )

    note = Note.new("", "100001", @author)
    note.save

    assert_equal "error", note.errors
  end
end
