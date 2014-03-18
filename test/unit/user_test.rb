require 'test_helper'

class UserTest < ActiveModel::TestCase

  context "attr_accessible" do
    should "not allow mass assignment of permissions" do
      user = User.create!(permissions: ['signin'])
      assert_nil user.reload.permissions
    end
  end

  context "a normal user" do
    should "just be a viewer" do
      user = create(:user)
      assert user.viewer?
      refute user.editor?
      refute user.admin?
    end
  end

  context "an editor" do
    should "be a viewer as well" do
      editor = create(:editor)
      assert editor.viewer?
      assert editor.editor?
      refute editor.admin?
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
end
