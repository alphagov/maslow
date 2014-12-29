require_relative '../test_helper'

class NeedStatusTest < ActiveSupport::TestCase
  context "(invalid status)" do
    should "split the reasons into common and custom reasons" do
      status = NeedStatus.new(reasons: [ NeedStatus::COMMON_REASONS_WHY_INVALID.first, "some other reason" ])

      assert_equal [ NeedStatus::COMMON_REASONS_WHY_INVALID.first ], status.common_reasons_why_invalid
      assert_equal "some other reason", status.other_reasons_why_invalid
    end
  end
end
