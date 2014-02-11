require 'test_helper'

class UserTest < ActiveModel::TestCase

  context "attr_accessible" do
    should "not allow mass assignment of permissions" do
      user = User.create!(permissions: ['signin'])
      assert_nil user.reload.permissions
    end
  end

end
