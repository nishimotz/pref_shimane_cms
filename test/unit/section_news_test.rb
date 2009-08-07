require File.dirname(__FILE__) + '/../test_helper'

class SectionNewsTest < Test::Unit::TestCase
  fixtures :section_news

  # Replace this with your real tests.
  def test_truth
    assert_kind_of SectionNews, section_news(:first)
  end
end
