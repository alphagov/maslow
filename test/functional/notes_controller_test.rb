require_relative '../integration_test_helper'
require 'gds_api/test_helpers/need_api'
require 'gds_api/test_helpers/organisations'

class NotesControllerTest < ActionController::TestCase
  include GdsApi::TestHelpers::NeedApi
  include GdsApi::TestHelpers::Organisations

  setup do
    login_as_stub_editor
  end

  context "POST create" do
    should "be successful" do
      @note_atts = {
        "note" => {
          "text" => "test"
        },
        "need_id" => "100001"
      }
      need_api_has_content_id_for_need(id: @note_atts["need_id"], content_id: SecureRandom.uuid)

      post :create, @note_atts

      assert_redirected_to revisions_need_path("100001")
      assert_equal "Note saved", flash[:notice]
      refute flash[:error]
    end

    should "return an error message if the save fails" do
      @blank_note_atts = {
        "note" => {
          "text" => ""
        },
        "need_id" => "100002"
      }
      need_api_has_content_id_for_need(id: @blank_note_atts["need_id"], content_id: SecureRandom.uuid)

      post :create, @blank_note_atts

      assert_equal "Note couldn't be saved: Text can't be blank", flash[:error]
      refute flash[:notice]
    end

    should "stop viewers from creating notes" do
      login_as_stub_user
      post :create, @note_atts
      assert_redirected_to needs_path
    end
  end
end
