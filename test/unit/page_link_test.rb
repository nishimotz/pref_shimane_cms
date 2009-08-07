require File.dirname(__FILE__) + '/../test_helper'

class PageLinkTest < Test::Unit::TestCase
  fixtures :page_links, :pages, :page_contents

  def test_truth
    assert_kind_of PageLink, page_links('id_32')
  end
end
