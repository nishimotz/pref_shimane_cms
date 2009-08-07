<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta name="description" content="島根県" />
<meta name="keywords" content="島根県,自治体,行政" />
<link href="/stylesheets/default.css" media="screen,print,tv" rel="Stylesheet" type="text/css" />
<link href="/stylesheets/color.css" media="screen,print,tv" rel="Stylesheet" title="カラー" type="text/css" />
<link href="/stylesheets/aural.css" media="aural" rel="Stylesheet" title="音声" type="text/css" />
<link href="/stylesheets/hc.css" media="screen,tv" rel="alternate stylesheet" title="ハイコントラスト" type="text/css" />
<script src="/javascripts/prototype.js" type="text/javascript"></script>
<script src="/javascripts/common.js" type="text/javascript"></script>
<link rel="index" href="sitemap.html" />
<link rev="made" href="mailto:webmaster&#64;pref.shimane.lg.jp" />
<title>島根県 : 閲覧支援機能の設定</title>
  <style type="text/css">
    .config_entries {
      margin: 0 0 2em 1em;
    }
    p {
      margin: 1em 0;
    }
    div#header {
      width: 100%;
      height: 66px;
    }
    div#global_nav {
      clear: both;
    }
  </style>
  <script type="text/javascript">
    var RadioGroup = Class.create();
    RadioGroup.prototype = {
      initialize: function(form, name) {
        this.elements = $A(form[name]);
      },
      getValue: function() {
        return this.elements.detect(function(e) {
          return e.checked;
        }).value;
      },
      setValue: function(value) {
        this.elements.each(function(e) {
          if (e.value == value) {
            e.checked = true;
          }
        });
      }
    }

    var configForm = {
      defaultValues: $H({
        activex: "off",
        ruby: "off",
        size: "100%",
        css: "default"
      }),

      load: function() {
        this.defaultValues.each(function(e) {
          var value = getCookie(e.key);
          if (value.length == 0) {
            value = e.value;
          }
          var radioGroup = new RadioGroup($('config_form'), e.key);
          radioGroup.setValue(value);
        });
/*
        var ruby = getCookie('ruby');
        if (ruby != 'on'){
          if (document.getElementsByTagName('ruby').length != 0) {
            location.reload(true);
          }
        } else {
          if (document.getElementsByTagName('ruby').length == 0) {
            location.reload(true);
          }
        }
*/
      },

      save: function() {
        ["activex", "size"].each(function (name) {
          var radioGroup = new RadioGroup($('config_form'), name);
          setCookie(name, radioGroup.getValue());
        });
        var reload = false;
        ["ruby", "css"].each(function (name) {
          var old_val = getCookie(name);
          var radioGroup = new RadioGroup($('config_form'), name);
          var new_val = radioGroup.getValue();
          if (old_val != new_val) {
            setCookie(name, new_val);
            reload = true;
          }
        });
        if (reload) {
          setCookie('reload', 't');
        }
      },

      restoreDefaults: function() {
        this.defaultValues.each(function(e) {
          var radioGroup = new RadioGroup($('config_form'), e.key);
          radioGroup.setValue(e.value);
        });
      }
    }

    function save() {
      configForm.save();
      back();
    }

    function back() {
      if (location.href.match(/url=(.*)/)) {
        location.href = unescape(RegExp.$1);
      } else {
        location.href = '/';
      }
    }
  </script>
</head>

<body onload="configForm.load()">
<!-- ヘッダ -->
<div id="header">
<div class="logo"><a href="/"><img alt="島根県" height="66" src="/images/shimane.png" width="300" /></a><a href="#content_top"><img alt="本文へジャンプ" height="1" src="/images/blank.gif" width="1" /></a></div>
</div>

<!-- グローバルナビゲーション -->
<div id="global_nav">
<div class="button"><a href="http://www.pref.shimane.jp/bousai/">防災情報</a></div>
<div class="button"><a href="/section.html">組織別情報</a></div>
<div class="button"><a href="/life/">くらし</a></div>
<div class="button"><a href="/health/">健康・福祉</a></div>
<div class="button"><a href="/culture/">教育・文化</a></div>
<div class="button"><a href="/industry/">産業・雇用</a></div>
<div class="button"><a href="/infra/">社会基盤</a></div>
<div class="button"><a href="/admin/">行政情報</a></div>
</div>

<!-- ツール -->
<div id="search_nav">
<div lang="en" xml:lang="en" id="foreign_nav">
<a href="http://www.pref.shimane.jp/section/kokusai/foreign/kokusai-e/">English</a> |
<a href="http://www.pref.shimane.jp/section/kokusai/foreign/kokusai-c/">Chinese</a> |
<a href="http://www.pref.shimane.jp/section/kokusai/foreign/kokusai-k/">Korean</a> |
<a href="http://www.pref.shimane.jp/section/kokusai/foreign/kokusai-r/">Russian</a>
</div>
<form method="get" action="/cgi-bin/search.cgi">
<div id="tool">
<input type="text" tabindex="1" id="text" accesskey="K" name="query" size="30" value="" maxlength="1991" /> 
<input type="submit" tabindex="2" accesskey="D" value="検索" class="submit" />
</div>
</form>
</div>

<h1>閲覧支援機能の設定</h1>
<h2>アクセシビリティに配慮した島根県オリジナルの閲覧支援を提供しています。</h2>
<p>閲覧者が特別なソフトをダウンロードしなくても、ホームページ上のボタンをクリックするだけで、ホームページの音声読み上げやふりがな表示、文字拡大や色変更などを行えます。</p>
<p>ホームページのボタンをクリックして機能を使うこともできますし、下記の各機能について、自分に合った状態にあらかじめ設定しておくこともできます。</p>
<hr />
<form id="config_form" action="javascript:save()">
<p>項目を選択し、「設定ボタン」を押してください。</p>
  <div class="config_entries">
    <p>
    <img width="55" height="68" align="left" mce_src="/images/speak.png" alt="よみあげアイコン" title="よみあげアイコン" src="/images/speak.png" />&nbsp;&nbsp;ページの内容をよみあげる。 [<a href="./yomiage.html">つかいかた</a>]<br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="activex_off" name="activex" type="radio" value="off" />
    全画面よみあげを行う<br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="activex_on" name="activex" type="radio" value="on" />
    読み飛ばし、速度変更等の機能を利用する
    </p>
    <p>
    <img width="55" height="68" align="left" mce_src="/images/ruby_off.png" alt="ふりがなアイコン" title="ふりがなアイコン" src="/images/ruby_off.png" />
    &nbsp;&nbsp;文字にふりがなをつける。 [<a href="./furigana.html">つかいかた</a>]<br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="ruby_off" name="ruby" type="radio" value="off" />
    文字にふりがなをつけない<br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="ruby_on" name="ruby" type="radio" value="on" />
    文字にふりがなをつける
    </p>
    <p>
    <img width="55" height="68" align="left" mce_src="/images/large_off.png" alt="おおきくアイコン" title="おおきくアイコン" src="/images/large_off.png" />
    &nbsp;&nbsp;文字サイズを変更する。 [<a href="./ookiku.html">つかいかた</a>]<br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="size_100" name="size" type="radio" value="100%" />
    標準の大きさ(100%) <br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="size_200" name="size" type="radio" value="200%" />
    大きくする(200%) <br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="size_300" name="size" type="radio" value="300%" />
    特大にする(300%)
    </p>
    <p>
    <img width="55" height="68" align="left" mce_src="/images/color_on.png" alt="いろアイコン" title="いろアイコン" src="/images/color_on.png" />
    &nbsp;&nbsp;配色を変更する。 [<a href="./iro.html">つかいかた</a>]<br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="css_default" name="css" type="radio" value="default" />
    高コントラスト <br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="css_hc" name="css" type="radio" value="hc" />
    黒背景 <br />
    &nbsp;&nbsp;&nbsp;&nbsp;<input id="css_lc" name="css" type="radio" value="lc" />
    低コントラスト
    </p>
    <p>
    <input type="button" onclick="save()" value="設定" />
    <input type="button" onclick="back()" value="キャンセル" />
    <input type="button" onclick="configForm.restoreDefaults(); save();"
           value="標準の設定に戻す" />
    </p>
  </div>
</form>

<!-- フッタ -->
<div style="clear: both;">
<div id="footer">
<a href="/privacy.html">個人情報の取扱い</a> |
<a href="/cl.html">著作権・リンク等</a> |
<a href="/ac.html">アクセシビリティ</a>
</div>
</div>

<div id="note">
<address>島根県庁 〒690-8501 島根県松江市殿町1番地<br />電話：0852-22-5111（代）,
<a href="http://www.pref.shimane.lg.jp/phone.html">県機関の電話番号案内</a>,
<a href="http://www.pref.shimane.lg.jp/kochokoho/profile/site.html">島根県の位置</a>
<!--
<a href="http://www.pref.shimane.jp/map/kencho_annai.html">県庁案内</a>
-->
<br />
<a href="mailto:webmaster@pref.shimane.lg.jp">webmaster@pref.shimane.lg.jp</a>
</address>
</div>
<div style="clear: both;"></div>
</body>
</html>
