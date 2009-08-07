require "yaml"
require "webrick/cgi"
require "nkf"

class PostCGI < WEBrick::CGI
  GPG_HOME = "/var/www/.gnupg"
  ENCRYPT_ID = "www-data@localhost"
  CONFIG = YAML.load_file("post_cgi.conf")

  def initialize(*args)
    super(*args)
    @errors = []
    @data = {}
  end

  def format_error_message
    if @errors.empty?
      return ""
    end
    errors = @errors.collect { |err|
      "<li>" + WEBrick::HTMLUtils.escape(err) + "</li>"
    }.join
    return <<EOF
<ul class="board_error">
#{errors}
</ul>
EOF
  end

  def render_raw(mobile, res, body)
    if mobile
      res["Content-Type"] = "text/html"
      res.body = NKF.nkf('-Ws', body)
    else
      res["Content-Type"] = "text/html; charset=utf-8"
      res.body = body
    end
  end

  def render(mobile, res, template, params = {})
    content = expand_template(template, params)
    if mobile
      body = expand_template(LAYOUT_MOBILE_HTML,
                             :page_title => page_title,
                             :content_for_layout => content)
    else
      body = expand_template(LAYOUT_HTML,
                             :page_title => page_title,
                             :content_for_layout => content)
    end
    render_raw(mobile, res, body)
  end

  def expand_template(template, params = {})
    return template.gsub(/@@(\w+)@@/u) {
      WEBrick::HTMLUtils.escape(params[$1.intern].to_s)
    }.gsub(/!!(\w+)!!/u) {
      params[$1.intern].to_s
    }
  end

  def save_post_data(prefix, req, data)
    t = Time.now
    filename = t.strftime("%Y%m%d%H%M%S") + format("%06d", t.usec) +
      "." + Process.pid.to_s
    path = File.expand_path(prefix + "/" + filename, CONFIG[:post_dir_base])
    IO.popen("gpg -q --homedir #{CONFIG[:gpg_home]} --encrypt --armor -r #{CONFIG[:gpg_encrypt_id]} > #{path}", "w") do |f|
      h = data.merge(:date => t, :remote_addr => req.peeraddr[3])
      f.print(h.to_yaml)
    end
  end

  def page_title
    raise ScriptError.new("Please override page_title")
  end

  def mobile?(req)
    req['user-agent'] =~ %r[(DoCoMo|J-PHONE|Vodafone|MOT-|UP\.Browser|DDIPOCKET|ASTEL|PDXGW|Palmscape|Xiino|sharp pda browser|Windows CE|L-mode)]i
  end

  def utf8_query(req)
    if mobile?(req)
      req.query.inject({}){|h, (k, v)|
        v.each_data{|e| e.replace(NKF.nkf('-Sw', e))}
        h[NKF.nkf('-Sw', k)]=v
        h
      }
    else
      req.query.dup
    end
  end

  LAYOUT_HTML = <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<meta name="description" content="島根県" />
<meta name="keywords" content="島根県,自治体,行政" />
<link href="/stylesheets/default.css" media="screen,print,tv" rel="Stylesheet" type="text/css" />
<link href="/stylesheets/color.css" media="screen,print,tv" rel="Stylesheet" title="カラー" type="text/css" />
<link href="/stylesheets/aural.css" media="aural" rel="Stylesheet" title="音声" type="text/css" />
<link href="/stylesheets/hc.css" media="screen,tv" rel="alternate stylesheet" title="ハイコントラスト" type="text/css" />
<link rel="index" href="sitemap.html" />

<link rev="made" href="mailto:webmaster&#64;pref.shimane.lg.jp" />
<title>島根県 : @@page_title@@</title>
</head>

<body>
<div id="header">
<!-- top icon -->
<div id="to_top_image">
<a href="/"><img src="/images/symbol/pref_symbol_s.gif" alt="島根県公式ウェブサイト(トップに戻る)" width="87" height="87" /></a>
</div>
<p class="anchor_link"><a href="#skip_content">ヘッダを飛ばして本文へ</a></p>
<!-- top icon end -->

<!-- panel -->
<div id="normal_panel">
  <ul>
    <li><a href="/bousai_info/"><img src="/images/panel/emergency_s.gif" alt="防災・気象" width="40" height="28" /></a></li><!--
 --><li><a href="/section.html"><img src="/images/panel/section_s.gif" alt="組織別情報(各部局の公開情報)" width="40" height="28" /></a></li><!--
 --><li><a href="/environment/"><img src="/images/panel/environment_s.gif" alt="環境(リサイクルや景観に関する情報)" width="40" height="28" /></a></li><!--
 --><li><a href="http://www.kankou.pref.shimane.jp/"><img src="/images/panel/sightseeing_s.gif" alt="観光(観光とアクセス情報 しまね観光ナビ)" width="40" height="28" /></a></li><!--
 --><li><a href="/admin/"><img src="/images/panel/admin_s.gif" alt="県の取組み・一般(財政や政策等、県政の骨格に関する情報)" width="40" height="28" /></a></li><!--
 --><li><a href="/life/"><img src="/images/panel/life_s.gif" alt="くらし(健康・福祉や教育・文化に関する情報)" width="40" height="28" /></a></li><!--
 --><li><a href="/top_news.html"><img src="/images/panel/news_s.gif" alt="新着情報(サイト全般の新着情報)" width="40" height="28" /></a></li><!--
 --><li><a href="/infra/"><img src="/images/panel/infra_s.gif" alt="県土づくり(道路整備や河川・治水等、社会基盤情報)" width="40" height="28" /></a></li><!--
 --><li><a href="/industry/"><img src="/images/panel/industry_s.gif" alt="産業・雇用(農林水産業、商工業に関する情報)" width="40" height="28" /></a></li>
  </ul>
</div>
<!-- panel end -->

<!-- navi -->
<div id="head_navi">
<div id="navi_contents">

<div id="mail">
<p><a id="mail_to_admin" href="mailto:webmaster@pref.shimane.lg.jp">HP管理者にメールする</a></p>
<p><a id="sitemap"  href="http://www.pref.shimane.lg.jp/sitemap.html">サイトマップ</a></p>
</div>

<div id="search">
<ul id="lang">
<li><a href="http://www1.pref.shimane.lg.jp/contents/kokusai/kokusai-e/index.html">English</a> / </li><!--
--><li><a href="http://www1.pref.shimane.lg.jp/contents/kokusai/kokusai-c/index.html">Chinese</a> / </li><!--
--><li><a href="http://www1.pref.shimane.lg.jp/contents/kokusai/kokusai-k/index.html">Korean</a> / </li><!--
--><li><a href="http://www1.pref.shimane.lg.jp/contents/kokusai/kokusai-r/index.html">Russian</a></li>
</ul>
<div id="search_form">
<form method="get" action="/cgi-bin/search.cgi">
<input type="text" id="keyword" tabindex="1" accesskey="K" name="query" size="30" value="" maxlength="1991" /> 
<input type="submit" id="submit" tabindex="2" accesskey="D" value="キーワード検索" />
</form>
<a href="/usage.html">使い方</a> <a href="/rss.html">RSS</a>
</div>

</div>
<!-- search end -->

</div>
</div>
<!-- head_navi end -->

<p class="skip_anchor"><a name="skip_content">ここから本文</a></p>
<div style="clear: both;"></div>
</div>
<!-- header end -->
<div id="content" style="padding-top: 5px;">

!!content_for_layout!!

</div>
<!-- フッタ -->
<div style="clear: both;"></div>
<div id="footer">
  <div id="contact">
<address>島根県庁 〒690-8501 島根県松江市殿町1番地<br />電話：0852-22-5111（代）,
<a href="http://www.pref.shimane.lg.jp/phone.html">県機関の電話番号案内</a>,
<a href="http://www.pref.shimane.lg.jp/kochokoho/profile/site.html">島根県の位置</a>
<br />
<a href="mailto:webmaster@pref.shimane.lg.jp">webmaster@pref.shimane.lg.jp</a>
</address>
</div>
<div id="about">
<p>
<a href="/privacy.html">個人情報の取扱い</a> |
<a href="/cl.html">著作権・リンク等</a> |
<a href="/ac.html">アクセシビリティ</a>
</p>
</div>
</div>
</body>
</html>
EOF

  LAYOUT_MOBILE_HTML = <<EOF
<html><head><title>島根県 : @@page_title@@</title></head>
<body>
<a href="/">TOP</a>

!!content_for_layout!!

<hr>
<div>島根県<br />
〒690-8501<br />
島根県松江市殿町1番地<br />
電話:0852-22-5111(代)</div>
</body>
</html>
EOF
end
