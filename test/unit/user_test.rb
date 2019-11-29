require "test_helper"
require "gds-sso/lint/user_test"

class GDS::SSO::Lint::UserTest
  def user_class
    ::User
  end
end

class UserTest < ActiveSupport::TestCase
  context "a normal user" do
    should "just be a viewer" do
      user = create(:user)
      assert user.viewer?
      assert_not user.editor?
      assert_not user.admin?
    end
  end

  context "an editor" do
    should "be a viewer as well" do
      editor = create(:editor)
      assert editor.viewer?
      assert editor.editor?
      assert_not editor.admin?
    end
  end

  context "an admin" do
    should "be both a viewer and an editor" do
      admin = create(:admin)
      assert admin.viewer?
      assert admin.editor?
      assert admin.admin?
    end
  end

  context "toggle bookmarks" do
    should "update the users bookmarked needs" do
      user = create(:user)

      user.toggle_bookmark("c2639b9c-27af-4684-8635-6a149346d967")
      assert_equal %w(c2639b9c-27af-4684-8635-6a149346d967), user.bookmarks

      user.toggle_bookmark("f97b9f26-6a04-4ef8-aa75-b429a8662b5e")
      assert_equal %w(c2639b9c-27af-4684-8635-6a149346d967 f97b9f26-6a04-4ef8-aa75-b429a8662b5e), user.bookmarks

      user.toggle_bookmark("c2639b9c-27af-4684-8635-6a149346d967")
      assert_equal %w(f97b9f26-6a04-4ef8-aa75-b429a8662b5e), user.bookmarks
    end
  end
end
