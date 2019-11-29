require_relative "../integration_test_helper"

class NotesControllerTest < ActionController::TestCase
  setup do
    login_as_stub_editor
  end

  context "POST create" do
    should "be successful" do
      content_id = SecureRandom.uuid

      post :create, params: note_atts(content_id: content_id)

      assert_redirected_to revisions_need_path(content_id)
      assert_equal "Note saved", flash[:notice]
      assert_not flash[:error]
    end

    should "return an error message if the save fails" do
      blank_note_atts = note_atts(text: "")

      post :create, params: blank_note_atts

      assert_equal "Note couldn't be saved: Text can't be blank", flash[:error]
      assert_not flash[:notice]
    end

    should "stop viewers from creating notes" do
      login_as_stub_user
      post :create, params: note_atts
      assert_redirected_to needs_path
    end
  end

  def note_atts(content_id: SecureRandom.uuid, text: "test")
    {
      "note" => {
        "text" => text,
      },
      "content_id" => content_id,
    }
  end
end
