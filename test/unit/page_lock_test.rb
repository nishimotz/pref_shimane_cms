require File.dirname(__FILE__) + '/../test_helper'

class PageLockTest < Test::Unit::TestCase
  fixtures :page_locks

  # Replace this with your real tests.
  def test_truth
    assert_kind_of PageLock, page_locks(:first)
  end
end
