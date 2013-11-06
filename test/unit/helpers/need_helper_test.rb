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

  context "format_field_value" do
    should "return the field value when present" do
      assert_equal "foo", format_field_value("foo")
    end

    should "return 'blank' when empty" do
      output = format_field_value("")

      assert_equal "<em>blank</em>", output
      assert output.html_safe?
    end

    should "return 'blank' when nil" do
      output = format_field_value(nil)

      assert_equal "<em>blank</em>", output
      assert output.html_safe?
    end
  end

  context "format_field_name" do
    should "return a humanized and capitalized field name" do
      assert_equal "Organisation Ids", format_field_name("organisation_ids")
    end
  end
end
