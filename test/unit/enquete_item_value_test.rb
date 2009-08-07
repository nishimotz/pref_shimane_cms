require File.dirname(__FILE__) + '/../test_helper'

class EnqueteItemValueTest < Test::Unit::TestCase
  fixtures :enquete_item_values

  # Replace this with your real tests.
  def test_truth
    assert_kind_of EnqueteItemValue, enquete_item_values(:first)
  end
end
