require File.dirname(__FILE__) + '/../test_helper'

class HelpActionTest < Test::Unit::TestCase
  fixtures :help_actions

  # Replace this with your real tests.
  def test_truth
    assert_kind_of HelpAction, help_actions(:first)
  end
end
