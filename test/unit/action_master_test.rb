require File.dirname(__FILE__) + '/../test_helper'

class ActionMasterTest < Test::Unit::TestCase
  fixtures :action_masters

  # Replace this with your real tests.
  def test_truth
    assert_kind_of ActionMaster, action_masters(:one)
  end
end
