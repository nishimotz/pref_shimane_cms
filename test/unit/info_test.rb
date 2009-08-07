require File.dirname(__FILE__) + '/../test_helper'

class InfoTest < Test::Unit::TestCase
  fixtures :infos

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Info, infos(:id1)
  end
end
