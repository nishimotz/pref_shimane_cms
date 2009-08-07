require File.dirname(__FILE__) + '/../test_helper'

class EnqueteAnswerItemTest < Test::Unit::TestCase
  fixtures :page_contents, :pages, :page_links
  fixtures :enquete_answer_items

  def test_save
    page = Page.find(1)
    ei = EnqueteItem.new(:page => page, :no => 1, :name => "ご意見")
    ea = EnqueteAnswer.new(:page => page,
                           :answered_at => Time.now, :remote_addr => "0.0.0.0")
    item = EnqueteAnswerItem.new(:enquete_item => ei,
                                 :enquete_answer => ea,
                                 :value => "テストです。\r\n二行目です。")
    item.save
    item.reload
    assert_equal("テストです。\n二行目です。", item.value)
  end
end
