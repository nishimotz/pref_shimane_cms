require File.dirname(__FILE__) + '/../test_helper'

# Re-raise errors caught by the controller.
class HelpController; def rescue_action(e) raise e end; end

class HelpControllerTest < Test::Unit::TestCase
  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
