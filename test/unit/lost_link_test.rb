require File.dirname(__FILE__) + '/../test_helper'

class LostLinkTest < Test::Unit::TestCase
  fixtures :lost_links

  # Replace this with your real tests.
  def test_truth
    assert_kind_of LostLink, lost_links(:first)
  end

  def test_get_lost_links
    outsides = LostLink.get_lost_links(LostLink::INSIDE_TYPE, 1)
    assert_equal(2, outsides.size)
  end
end
