require File.dirname(__FILE__) + '/../test_helper'

class FilterTest < Test::Unit::TestCase
  include Filter
  def test_convert
    assert_equal("\244\242", convert('あ', 'utf-8', 'euc-jp'))
  end

  def test_convert_with_invalid_char
    assert_equal("\244\242", convert("あ\342\205\240", 'utf-8', 'euc-jp'))
  end

  def test_convert_with_block
    assert_equal("\244\242&#8544;",
                 convert("あ\342\205\240", 'utf-8', 'euc-jp'){|c| '&#%d;' % Iconv.conv('ucs-2be', 'utf-8', c).unpack('n').first}
                 )
  end

  def test_convert_with_invalid_encoding
    assert_raise(RuntimeError) {convert('あ', 'utf-8', 'invalid_encoding')}
  end

  def test_convert_non_japanese_chars
    assert_equal('あI',
                 convert_non_japanese_chars("あ\342\205\240"))
    assert_equal('あ(株)',
                 convert_non_japanese_chars("あ\343\210\261"))
    assert_equal('あ<span class="invalid">&#8750;</span>',
                 convert_non_japanese_chars("あ\342\210\256"))
  end

  def test_convert_tilda
    assert_equal('~',
                 convert_non_japanese_chars("~"))
    assert_equal('~',
                 remove_non_japanese_chars("~"))
  end

  def test_remove_non_japanese_chars
    assert_equal('あイウ',
                 remove_non_japanese_chars("あ\342\205\240イｳ"))
    assert_equal('あイｳ',
                 remove_non_japanese_chars("あ\342\205\240イｳ", false))
  end
end
