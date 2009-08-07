require File.dirname(__FILE__) + '/../test_helper'

class EnqueteAnswerTest < Test::Unit::TestCase
  fixtures :enquete_answers, :enquete_items

  def test_item_answers
    enq_ans = enquete_answers(:ans1)
    item = enquete_items(:pitem1)
    assert_equal 'value1,value1_2,value1_3:other value', enq_ans.item_answers(item)
  end
end
