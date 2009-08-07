require File.dirname(__FILE__) + '/../test_helper'

class WordTest < Test::Unit::TestCase
  fixtures :words

  def test_last_modified
    assert(Time.local(2006, 1, 5, 10, 0, 0), Word.last_modified)
  end

  def test_validation
    errors = Word.create(:base => '漢 字', :text => 'かんじ').errors
    assert_equal("見出し語に不正な文字が含まれています。", errors[:base])
    errors = Word.create(:base => 'abc', :text => 'えーびーしー').errors
    assert_equal("見出し語に不正な文字が含まれています。", errors[:base])
    errors = Word.create(:base => 'ａｂｃ', :text => 'えーびーしー').errors
    assert_nil(errors[:base])
    errors = Word.create(:base => '漢字漢字', :text => 'カンジかんじａ').errors
    assert_equal("に不正な文字が含まれています。", errors[:text])
    errors = Word.create(:base => '漢字漢字', :text => 'カンジｶﾝｼﾞ').errors
    assert_equal("に不正な文字が含まれています。", errors[:text])
    errors = Word.create(:base => '漢字漢字', :text => 'カンジカンジ').errors
    assert_nil(errors[:text])
  end
end
