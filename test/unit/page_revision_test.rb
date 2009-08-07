require File.dirname(__FILE__) + '/../test_helper'

class PageRevisionTest < Test::Unit::TestCase
  fixtures :page_revisions, :pages

  def test_relationship
    page = Page.find(1)
    assert_equal(2, page.revisions.size)
    assert_equal([PageRevision.find(2), PageRevision.find(1)], page.revisions)
  end
end
