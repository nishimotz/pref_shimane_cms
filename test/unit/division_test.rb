require File.dirname(__FILE__) + '/../test_helper'

class DivisionTest < Test::Unit::TestCase
  fixtures :divisions, :sections

  def test_relation
    assert_equal(1, divisions(:division1).sections.size)
    assert_equal(3, divisions(:division2).sections.size)
  end
end
