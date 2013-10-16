require_relative '../../test_helper'

class NeedHelperTest < ActiveSupport::TestCase
  include NeedHelper

  context "format_need_goal" do
    should "capitalize the first letter of a need goal" do
      assert_equal "Pay my car tax", format_need_goal("pay my car tax")
    end

    should "not modify the remainder of the string" do
      assert_equal "Find out about VAT", format_need_goal("find out about VAT")
      assert_equal "Apply for Carers' Allowance", format_need_goal("apply for Carers' Allowance")
    end
  end
end
