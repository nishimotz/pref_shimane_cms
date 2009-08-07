#!/usr/bin/ruby -w

require 'fileutils'
require 'test/unit'
$:.unshift(File.expand_path(File.dirname(__FILE__)))
FileUtils.cp('post_cgi.conf.test', 'post_cgi.conf')

eval(File.read(File.expand_path(File.dirname(__FILE__) + "/enquete.cgi")), binding, 'enquete.cgi')

class EnqueteCGI
  attr_accessor :page_src, :answers
  CONFIG[:enquete_cgi] = 'http://localhost/cgi-bin/enquete.cgi'
end

class EnqueteCGITest < Test::Unit::TestCase
  def setup
    @cgi = EnqueteCGI.new
    FileUtils.cp('post_cgi.conf.test', 'post_cgi.conf')
  end

  def teardown
    FileUtils.rm('post_cgi.conf') if File.exist?('post_cgi.conf')
  end

  def test_create_hidden_answers
    @cgi.answers = {'選択式複数回答可' => ['こた,え2','こたえ3']}

    assert_equal %{<input name="選択式複数回答可" value="こた,え2" type="hidden" /><input name="選択式複数回答可" value="こたえ3" type="hidden" />}, @cgi.create_hidden_answers
  end

  def test_create_commit_form
    @cgi.answers = {'選択式複数回答可' => ['こた,え2','こたえ3']}
    @cgi.instance_variable_set("@page_uri", "/foo.html")
    @cgi.instance_variable_set("@page_id", "1")
    @cgi.instance_variable_set("@cgi_uri", "http://localhost:3001/cgi-bin/enquete.cgi")

    assert_equal <<FORM, @cgi.create_commit_form
<form method="post" action="http://localhost:3001/cgi-bin/enquete.cgi">
<input type="hidden" name="_page_id" value="1" />
<input type="hidden" name="_uri" value="/foo.html" />
<input name="選択式複数回答可" value="こた,え2" type="hidden" /><input name="選択式複数回答可" value="こたえ3" type="hidden" />
<input name="_reedit" type="submit" value="アンケート画面に戻る" />
<input name="_commit" type="submit" value="送信" />
</form>
FORM
  end

  def test_apply_answers
    src = <<HTML
<p>&nbsp;</p>
<input name="選択式" value="回答1" type="radio" /> 回答1<br />
<input name="選択式" type="radio" value="回答2" /> 回答2<br />
<input name="選択式複数回答可" type="checkbox" value="こたえ1" /> こたえ1<br />
<input name="選択式複数回答可" type="checkbox" value="こたえ2" /> こたえ2
<input name="選択式複数回答可_other" size="80" type="text" value="" disabled />
<input name="一行入力欄*" size="80" type="text" value="" />
<textarea cols="80" name="複数行入力欄" rows="6" style="width: 80%;"></textarea>
<input name="commit" type="submit" value="送信" />
<p>&nbsp;</p>
HTML
    @cgi.answers = { '選択式' => ["回答1"],
                     '選択式複数回答可' => ['こたえ1','こたえ2'],
                     '選択式複数回答可_other' => ['その他'],
                     '一行入力欄' => ['bar'],
                     '複数行入力欄' => ['foo']}

    @cgi.apply_answers!(src)
    assert_equal <<REPLACED, src
<p>&nbsp;</p>
<input name="選択式" value="回答1" type="radio" checked="checked" /> 回答1<br />
<input name="選択式" type="radio" value="回答2" /> 回答2<br />
<input name="選択式複数回答可" type="checkbox" value="こたえ1" checked="checked" /> こたえ1<br />
<input name="選択式複数回答可" type="checkbox" value="こたえ2" checked="checked" /> こたえ2
<input name="選択式複数回答可_other" size="80" type="text" value="その他" disabled />
<input name="一行入力欄*" size="80" type="text" value="bar" />
<textarea cols="80" name="複数行入力欄" rows="6" style="width: 80%;">foo</textarea>
<input name="commit" type="submit" value="送信" />
<p>&nbsp;</p>
REPLACED
  end

  def test_enable_answered_other_input
    html = <<HTML
<input name="選択式複数回答可_other" size="80" type="text" value="some value" disabled />
<input name="選択式複数回答可_other" size="80" type="text" value="" disabled />
HTML
    @cgi.enable_answered_other_input!(html)
    assert_equal <<REPLACED, html
<input name="選択式複数回答可_other" size="80" type="text" value="some value"  />
<input name="選択式複数回答可_other" size="80" type="text" value="" disabled />
REPLACED
  end

  def test_emphasized_src
    @cgi.instance_variable_set("@cgi_uri", "http://localhost:3001/cgi-bin/enquete.cgi")
    @cgi.page_src = <<HTML
<form method="post" action="http://localhost:3001/cgi-bin/enquete.cgi">
<input name="必須入力*" size="80" value="" />必須入力
</form>
HTML
    @cgi.answers = {'必須入力*' => '' }
    assert_equal <<REPLACED, @cgi.emphasized_src
<p style="padding: 10px; color:red; border:2px inset red;">※入力されていない箇所があります。</p><form method="post" action="http://localhost:3001/cgi-bin/enquete.cgi">
<strong style="color:red">必須入力です</strong><br /><input name="必須入力*" size="80" value="" />必須入力
</form>
REPLACED

  end

  def test_uncheck_checkbox_and_radio
   src = <<HTML
<input name="選択式" checked="checked" type="radio" value="回答2" /> 回答2<br />
<input name="選択式複数回答可" type="checkbox" checked="checked" value="こたえ1" /> こたえ1<br />
HTML
    @cgi.uncheck_checkbox_and_radio!(src)
    assert_equal <<REPLACED, src
<input name="選択式" type="radio" value="回答2" /> 回答2<br />
<input name="選択式複数回答可" type="checkbox" value="こたえ1" /> こたえ1<br />
REPLACED
  end

  def test_apply_answer_to_radio_or_checkbox
    s = %{<input name="選択式複数回答可" type="checkbox" value="こたえ1" />}
    expected = %{<input name="選択式複数回答可" type="checkbox" value="こたえ1" checked="checked" />}
    assert_equal expected, @cgi.apply_answer_to_radio_or_checkbox(s)
  end

  def test_apply_answer_to_text
    s = %{<input name="一行入力欄" type="text" value="" />}
    value = '入力'
    expected = %{<input name="一行入力欄" type="text" value="入力" />}
    assert_equal expected, @cgi.apply_answer_to_text(s, value)
  end

  def test_apply_answer_to_textarea
    s = %{<textarea cols="80" name="複数行入力欄" rows="6" style="width: 80%;">}
    value = '入力'
    expected = %{<textarea cols="80" name="複数行入力欄" rows="6" style="width: 80%;">入力}
    assert_equal expected, @cgi.apply_answer_to_textarea(s, value)
  end

  def test_create_confirm_form
    src = <<HTML
<input type="hidden" name="_page_id" value="1" />
<input type="hidden" name="_uri" value="/foo.html" />
<p>&nbsp;</p>
<input name="選択式" value="回答1" type="radio" /> 回答1<br />
<input name="選択式" type="radio" value="回答2" /> 回答2<br />
<input name="選択式複数回答可" type="checkbox" value="こたえ1" /> こたえ1<br />
<input name="選択式複数回答可" type="checkbox" value="こたえ2" /> こたえ2
<input name="選択式複数回答可_other" size="80" type="text" value="" disabled />
<p>問2）一行入力欄</p>
<input name="一行入力欄" size="80" type="text" value="" />
<p>問3）複数行入力欄</p>
<textarea cols="80" name="複数行入力欄" rows="6" style="width: 80%;"></textarea>
<input name="commit" type="submit" value="送信" />
<p>&nbsp;</p>
HTML
    @cgi.answers = { '選択式' => ["回答1"],
                     '選択式複数回答可' => ['こたえ1','こたえ2'],
                     '選択式複数回答可_other' => ['その他'],
                     '一行入力欄' => ['bar'],
                     '複数行入力欄' => ['foo']}
    assert_equal <<REPLACED.strip, @cgi.create_confirm_form(src)
<p>&nbsp;</p>
<img src="/images/checkbox_checked.gif" alt="選択" /> 回答1<br />
<img src="/images/checkbox_notchecked.gif" alt="未選択" /> 回答2<br />
<img src="/images/checkbox_checked.gif" alt="選択" /> こたえ1<br />
<img src="/images/checkbox_checked.gif" alt="選択" /> こたえ2
<div style="width: 50em; height: 1.5em; border: 2px inset #999;">その他</div>
<p>問2）一行入力欄</p>
<div style="width: 50em; height: 1.5em; border: 2px inset #999;">bar</div>
<p>問3）複数行入力欄</p>
<div style="width: 80%; height: 8em; overflow: auto; border: 2px inset #999;">foo</div>

<p>&nbsp;</p>
REPLACED
  end

  def test_replace_form_control_checkbox
    src = <<HTML
<input name="選択式複数回答可" type="checkbox" value="こたえ1" /> こたえ1<br />
<input name="選択式複数回答可" type="checkbox" value="こたえ2" checked="checked" /> こたえ2<br />
HTML
    @cgi.replace_form_control!(src)
    assert_equal <<REPLACED.strip, src
<img src="/images/checkbox_notchecked.gif" alt="未選択" /> こたえ1<br />
<img src="/images/checkbox_checked.gif" alt="選択" /> こたえ2<br />
REPLACED
  end

  def test_replace_form_control_radio
    src = <<HTML
<input name="選択式" value="回答1" type="radio" checked="checked" /> 回答1<br />
<input name="選択式" type="radio" value="回答2" /> 回答2<br />
HTML
    @cgi.replace_form_control!(src)
    assert_equal <<REPLACED.strip, src
<img src="/images/checkbox_checked.gif" alt="選択" /> 回答1<br />
<img src="/images/checkbox_notchecked.gif" alt="未選択" /> 回答2<br />
REPLACED
  end

  def test_replace_form_control_hidden
    src = <<HTML
<input type="hidden" name="_page_id" value="1" />
HTML
    @cgi.replace_form_control!(src)
    assert_equal "", src
  end

  def test_replace_form_control_submit
    src = <<HTML
<input type="submit" name="commit" value="送信" />
HTML
    @cgi.replace_form_control!(src)
    assert_equal "", src
  end

  def test_replace_form_control_text
    src = <<HTML
<input name="一行入力欄" size="80" type="text" value="foo" />
<input name="一行入力欄" size="80" type="text" value="" />
HTML
    @cgi.replace_form_control!(src)
    assert_equal <<REPLACED.strip, src
<div style="width: 50em; height: 1.5em; border: 2px inset #999;">foo</div>
<div style="width: 50em; height: 1.5em; border: 2px inset #999;"></div>
REPLACED
  end

  def test_replace_form_control_textarea
    src = <<HTML
<textarea cols="80" name="複数行入力欄" rows="6" style="width: 80%;">foo</textarea>
HTML
    @cgi.replace_form_control!(src)
    assert_equal <<REPLACED.strip, src
<div style="width: 80%; height: 8em; overflow: auto; border: 2px inset #999;">foo</div>
REPLACED
  end

  def test_create_confirmation_page
    @cgi.instance_variable_set("@page_uri", "/foo.html")
    @cgi.instance_variable_set("@page_id", "1")
    @cgi.instance_variable_set("@cgi_uri", "http://localhost:3001/cgi-bin/enquete.cgi")
    @cgi.page_src = <<HTML
<html>
<body>
<form method="post" action="http://localhost:3001/cgi-bin/enquete.cgi">
<input type="hidden" name="_page_id" value="1" />
<input type="hidden" name="_uri" value="/foo.html" />
<input name="入力" type="text" size="80" value="" />入力
</form>
</body>
</html>
HTML
    @cgi.answers = {'入力' => ['foo'] }
    assert_equal <<REPLACED, @cgi.create_confirmation_page
<html>
<body>
<h1>入力確認画面</h1>
<div style="width: 50em; height: 1.5em; border: 2px inset #999;">foo</div>入力
<form method="post" action="http://localhost:3001/cgi-bin/enquete.cgi">
<input type="hidden" name="_page_id" value="1" />
<input type="hidden" name="_uri" value="/foo.html" />
<input name="入力" value="foo" type="hidden" />
<input name="_reedit" type="submit" value="アンケート画面に戻る" />
<input name="_commit" type="submit" value="送信" />
</form>

</body>
</html>
REPLACED
  end

  def test_is_empty
    assert @cgi.is_empty?("")
    assert @cgi.is_empty?(" ")
    assert @cgi.is_empty?("  ")
    assert @cgi.is_empty?(" \t \n ")
  end
end
