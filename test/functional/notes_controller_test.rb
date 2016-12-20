require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'
require 'gds_api/test_helpers/organisations'

class NotesControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::NeedApi
  include GdsApi::TestHelpers::Organisations

  setup do
    login_as_stub_editor
    @note_atts = {
      "notes" => {
        "text" => "test"
      },
      "need_id" => "100001"
    }
  end

  context "POST create" do
    should "be successful" do
      stub_create_note(
        "text" => "test",
        "need_id" => "100001",
        "author" => {
          "name" => stub_user.name,
          "email" => stub_user.email,
          "uid" => stub_user.uid
        }
      )

      post :create, @note_atts

      assert_redirected_to revisions_need_path("100001")
      assert_equal "Note saved", @controller.flash[:notice]
      refute @controller.flash[:error]
    end

    should "return an error message if the save fails" do
      Note.any_instance.expects(:save).returns(false)
      Note.any_instance.expects(:errors).returns("Text can't be blank")

      post :create, @note_atts

      assert_equal "Note couldn't be saved: Text can't be blank", @controller.flash[:error]
      refute @controller.flash[:notice]
    end

    should "stop viewers from creating notes" do
      login_as_stub_user
      post :create, @note_atts
      assert_redirected_to needs_path
    end
  end
end
