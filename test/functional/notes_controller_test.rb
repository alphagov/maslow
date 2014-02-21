require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'

class NotesControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::NeedApi

  setup do
    login_as stub_user
    @note_atts = {
      "notes" => {
        "text" => "test"
      },
      "need_id" => "100001"
    }
  end

  context "POST create" do
    should "be successful" do
      GdsApi::NeedApi.any_instance.expects(:create_note).with(
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

      post :create, @note_atts

      assert_equal "Error saving note", @controller.flash[:error]
      refute @controller.flash[:notice]
    end
  end
end
