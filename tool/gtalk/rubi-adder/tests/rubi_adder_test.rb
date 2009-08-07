require 'test/unit'
require 'rubi_adder'

$KCODE = 'u'

class RubiAdderTest < Test::Unit::TestCase
  def test_add__word
    result = RubiAdder.add('島根')
    expect = '<ruby>島根<rp>(</rp><rt>しまね</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)

    result = RubiAdder.add('島根県庁')
    expect =
      '<ruby>島根<rp>(</rp><rt>しまね</rt><rp>)</rp></ruby>' +
      '<ruby>県庁<rp>(</rp><rt>けんちょう</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)

    result = RubiAdder.add('島根県庁情報政策課')
    expect =
      '<ruby>島根<rp>(</rp><rt>しまね</rt><rp>)</rp></ruby>' +
      '<ruby>県庁<rp>(</rp><rt>けんちょう</rt><rp>)</rp></ruby>' +
      '<ruby>情報<rp>(</rp><rt>じょうほう</rt><rp>)</rp></ruby>' +
      '<ruby>政策<rp>(</rp><rt>せいさく</rt><rp>)</rp></ruby>' +
      '<ruby>課<rp>(</rp><rt>か</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)

    result = RubiAdder.add('左右')
    expect =
      '<ruby>左右<rp>(</rp><rt>さゆう</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)
  end

  def test_add__added_rubi_word
    result = RubiAdder.add('<ruby>島根県庁<rp>(</rp>' +
                           '<rt>しまねけんちょう</rt><rp>)</rp></ruby>')
    expect =
      '<ruby>島根県庁<rp>(</rp><rt>しまねけんちょう</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)
  end
  
  def test_add__include_okurigana
    result = RubiAdder.add('多く')
    expect =
      '<ruby>多<rp>(</rp><rt>おお</rt><rp>)</rp></ruby>' +
      'く'
    assert_equal(expect, result)
    
    result = RubiAdder.add('その他')
    expect =
      'その' +
      '<ruby>他<rp>(</rp><rt>た</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)

    result = RubiAdder.add('取締り')
    expect =
      '<ruby>取締<rp>(</rp><rt>とりしま</rt><rp>)</rp></ruby>' +
      'り'
    assert_equal(expect, result)
    
    result = RubiAdder.add('呼び出す')
    expect =
      '<ruby>呼び出<rp>(</rp><rt>よびだ</rt><rp>)</rp></ruby>' +
      'す'
    assert_equal(expect, result)

=begin
    result = RubiAdder.add('呼び出す')
    expect =
      '<ruby>呼<rp>(</rp><rt>よ</rt><rp>)</rp></ruby>' +
      'び' +
      '<ruby>出<rp>(</rp><rt>だ</rt><rp>)</rp></ruby>' +
      'す'
    assert_equal(expect, result)
=end
  end

  def test_add__zenkaku_alphabet_and_number
    data = ['２１', 'ＧＷ']
    data.each do |s|
      assert_equal(s, RubiAdder.add(s))
    end
  end

  def test_add__sentence
    result = RubiAdder.add('第407回島根県議会の開会に当たり、')
    expect =
      '<ruby>第<rp>(</rp><rt>だい</rt><rp>)</rp></ruby>' +
      '407' +
      '<ruby>回<rp>(</rp><rt>かい</rt><rp>)</rp></ruby>' +
      '<ruby>島根<rp>(</rp><rt>しまね</rt><rp>)</rp></ruby>' +
      '<ruby>県議会<rp>(</rp><rt>けんぎかい</rt><rp>)</rp></ruby>' +
      'の' +
      '<ruby>開会<rp>(</rp><rt>かいかい</rt><rp>)</rp></ruby>' +
      'に' +
      '<ruby>当<rp>(</rp><rt>あ</rt><rp>)</rp></ruby>' +
      'たり、'
    assert_equal(expect, result)

    result = RubiAdder.add('諸議案の説明等に先立ちまして、一言申し上げます。')
    expect =
      '<ruby>諸<rp>(</rp><rt>しょ</rt><rp>)</rp></ruby>' +
      '<ruby>議案<rp>(</rp><rt>ぎあん</rt><rp>)</rp></ruby>' +
      'の' +
      '<ruby>説明<rp>(</rp><rt>せつめい</rt><rp>)</rp></ruby>' +
      '<ruby>等<rp>(</rp><rt>とう</rt><rp>)</rp></ruby>' +
      'に' +
      '<ruby>先立<rp>(</rp><rt>さきだ</rt><rp>)</rp></ruby>' +
      'ちまして、' +
      '<ruby>一言<rp>(</rp><rt>ひとこと</rt><rp>)</rp></ruby>' +
      '<ruby>申し上<rp>(</rp><rt>もうしあ</rt><rp>)</rp></ruby>' +
      'げます。'
    assert_equal(expect, result)
  end

  def test_add__multi_line_sentence
    sentence = <<EOS
第407回
島根県
議会の
開会に
当たり、
EOS
    result = RubiAdder.add(sentence)
    expect =
      '<ruby>第<rp>(</rp><rt>だい</rt><rp>)</rp></ruby>' +
      '407' +
      '<ruby>回<rp>(</rp><rt>かい</rt><rp>)</rp></ruby>' +
      "\n" +
      '<ruby>島根<rp>(</rp><rt>しまね</rt><rp>)</rp></ruby>' +
      '<ruby>県<rp>(</rp><rt>けん</rt><rp>)</rp></ruby>' +
      "\n" +
      '<ruby>議会<rp>(</rp><rt>ぎかい</rt><rp>)</rp></ruby>' +
      'の' +
      "\n" +
      '<ruby>開会<rp>(</rp><rt>かいかい</rt><rp>)</rp></ruby>' +
      'に' +
      "\n" +
      '<ruby>当<rp>(</rp><rt>あ</rt><rp>)</rp></ruby>' +
      'たり、' +
      "\n"
    assert_equal(expect, result)
  end
  
  def test_add__html
    html =<<EOS
<?xml version="1.0" encoding="Shift_JIS"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS" />
<title>ルビふり不要</title>
</head>
<body>
ルビふり | 必要
</body>
</html>
EOS
    expect =<<EOS
<?xml version="1.0" encoding="Shift_JIS"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS" />
<title>ルビふり不要</title>
</head>
<body>
ルビふり | <ruby>必要<rp>(</rp><rt>ひつよう</rt><rp>)</rp></ruby>
</body>
</html>
EOS
    assert_equal(expect, RubiAdder.add(html))
  end
  
  def test_add__chasen_unknown_word
    result = RubiAdder.add('避く')
    expect =
      '<ruby>避<rp>(</rp><rt>ひ</rt><rp>)</rp></ruby>' +
      'く'
    assert_equal(expect, result)

    result = RubiAdder.add('協働')
    expect =
      '<ruby>協<rp>(</rp><rt>きょう</rt><rp>)</rp></ruby>' +
      '<ruby>働<rp>(</rp><rt>どう</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)

=begin
    result = RubiAdder.add('神々')
    expect =
      '<ruby>神<rp>(</rp><rt>かみ</rt><rp>)</rp></ruby>' +
      '<ruby>々<rp>(</rp><rt>がみ</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)

    result = RubiAdder.add('神々')
    expect =
      '<ruby>神々<rp>(</rp><rt>かみがみ</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)
=end
  end

  def test_add__exceptions
    result = RubiAdder.add('大リーグ')
    expect = 
      '<ruby>大<rp>(</rp><rt>だい</rt><rp>)</rp></ruby>' +
      'リーグ'
    assert_equal(expect, result)

    result = RubiAdder.add('ドルに対する円の変動幅が')
    expect =
      'ドルに' +
      '<ruby>対<rp>(</rp><rt>たい</rt><rp>)</rp></ruby>' +
      'する' + 
      '<ruby>円<rp>(</rp><rt>えん</rt><rp>)</rp></ruby>' +
      'の' +
      '<ruby>変動<rp>(</rp><rt>へんどう</rt><rp>)</rp></ruby>' +
      '<ruby>幅<rp>(</rp><rt>はば</rt><rp>)</rp></ruby>' +
      'が'
    assert_equal(expect, result)

=begin
    result = RubiAdder.add('１２月')
    expect = 
      '１２' +
      '<ruby>月<rp>(</rp><rt>がつ</rt><rp>)</rp></ruby>'
    assert_equal(expect, result)
=end
  end
end
