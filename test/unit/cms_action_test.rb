require File.dirname(__FILE__) + '/../test_helper'

class CmsActionTest < Test::Unit::TestCase
  fixtures :cms_actions

  # Replace this with your real tests.
  def test_truth
    assert_kind_of CmsAction, cms_actions(:one)
  end
end
