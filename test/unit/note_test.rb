require_relative '../test_helper'

class NoteTest < ActiveSupport::TestCase
  should "send note data to the need api" do
    @author = OpenStruct.new(
      name: "Winston Smith-Churchill",
      email: "winston@alphagov.co.uk",
      uid: "win5t0n"
    )

    GdsApi::NeedApi.any_instance.expects(:create_note).with(
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
end
