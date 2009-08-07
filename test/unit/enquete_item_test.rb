require File.dirname(__FILE__) + '/../test_helper'

class EnqueteItemTest < Test::Unit::TestCase
  fixtures :enquete_items, :enquete_answers, :pages, :enquete_answer_items

  # Replace this with your real tests.
  def test_answer_values_empty
    enquete_item = EnqueteItem.new(:name => 'foo')
    assert_equal [],  enquete_item.answer_values
  end

  def test_answer_values_exist
    enquete_item = EnqueteItem.new(:name => 'foo')
    enquete_item.enquete_answer_items.create(:value => 'bar')
    enquete_item.enquete_answer_items.create(:value => '  ')
    enquete_item.enquete_answer_items.create(:value => 'barbar')
    assert_equal ['bar', 'barbar'],  enquete_item.answer_values.sort
  end

  def test_not_checkbox_or_radio
    enquete_item = EnqueteItem.new(:name => 'foo')
    assert !enquete_item.checkbox_or_radio?
  end

  def test_checkbox_or_radio
    enquete_item = EnqueteItem.new(:name => 'foo')
    enquete_item.enquete_item_values.create(:value => 'foo')
    assert enquete_item.checkbox_or_radio?
  end

  def test_count_answer_by_value
    enquete_item = enquete_items(:item2)
    enquete_item.enquete_answer_items.clear

    assert_equal 0, enquete_item.count_answer_by_value('bar')

    enquete_answer = enquete_answers(:ans1)
    enquete_item.enquete_answer_items.create(:value => 'bar',
                                             :enquete_answer  => enquete_answer )
    assert_equal 1, enquete_item.count_answer_by_value('bar')

    enquete_item.enquete_answer_items.create(:value => 'foo',
                                             :enquete_answer => enquete_answer )
    assert_equal 1, enquete_item.count_answer_by_value('bar')
  end

  def test_answered_count
    enquete_item1 = enquete_items(:answered_count1)
    assert 2, enquete_item1.answered_count
    enquete_item0 = enquete_items(:answered_count0)
    assert 0, enquete_item0.answered_count
  end

  def test_other_answer_values
    enquete_item0 = enquete_items(:answered_count0) 
    assert_equal ['other1', 'other2'], enquete_item0.other_answer_values.sort
  end
end
