require File.dirname(__FILE__) + '/../test_helper'

class EmergencyInfoTest < Test::Unit::TestCase
  fixtures :emergency_infos

  # Replace this with your real tests.
  def test_truth
    assert_kind_of EmergencyInfo, emergency_infos(:first)
  end
end
