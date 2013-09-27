require_relative '../integration_test_helper'

# TODO: Remove this spec once real specs exist. This is just for CI.
#
class DefaultTest < ActionDispatch::IntegrationTest

  setup do
    login_as_stub_user
  end

  should "display some test text" do
    visit "/"
    assert page.has_content? "Test output. Remove this once real specs exist."
  end

end
