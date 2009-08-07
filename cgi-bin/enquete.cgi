#!/usr/bin/ruby -Ku
require "open-uri"
require "net/smtp"
require 'tmail'
require "post_cgi"

class EnqueteCGI < PostCGI
  SERVER = 'localhost'
  MAILMAGAZINE_REGEXP = /.*?@#{Regexp.quote(CONFIG[:mailmagazine_domain])}/
  POST_HTML = <<EOF
<h1>送信完了</h1>
<p>送信しました。</p>
<p>ありがとうございました。</p>
<p><a href="@@back_uri@@">戻る</a></p>
<p><a href="http://www.pref.shimane.lg.jp/">県トップページへ</a></p><br />
EOF

  def do_POST(req, res)
    @mobile = mobile?(req)
    @query = utf8_query(req)
    @cgi_uri = req.request_uri.to_s
    @page_id = @query["_page_id"]
    @page_uri = @query["_uri"]
    @answers = extract_answers_from_query
    @page_src = get_page_src

    if reedit?
      #Return to enqute page with inputs fill with answers.
      render_edit(res)
    elsif commit?
      #Send answer to the server.
      do_commit(req, res)
    else
      if missing_keys.any?
        #Return to enqute page, and notify user of missing answers.
        render_warning(res)
      else
        #OK, proceed to comfirmantion page.
        render_confirm(res, @page_src)
      end
    end
  end

  def reedit?
    @query.has_key? "_reedit"
  end

  def commit?
    @query.has_key? "_commit"
  end

  def mail_form?
    @answers.any? { |k,| k =~ MAILMAGAZINE_REGEXP }
  end

  def extract_answers_from_query
    answers = @query.dup
    %w{_page_id _uri commit}.each {|key| answers.delete(key)}
    answers.keys.grep(/\*\z/).each {|key|
      answers[key.sub(/\*\z/, '')] = answers[key]
      answers.delete(key)
    }
    answers.each do |k, v|
      answers[k] = v.list
    end
    answers
  end

  def get_page_src
    uri = CONFIG[:doc_root] + @page_uri
    uri << "index.html" if %r!/\z! =~ uri
    if @mobile
      uri << ".i" unless uri =~ /\.i\z/
      NKF.nkf('-Sw', File.read(uri))
    else
      File.read(uri)
    end
  end

  def missing_keys
    return @missing_keys if @missing_keys
    mandatory_keys = @page_src.scan(/<(?:input|textarea)[^>]*name="([^"]+?)\*"/).collect{|i,| i}.uniq
    mandatory_keys.concat(@answers.keys.grep(MAILMAGAZINE_REGEXP))
    @missing_keys = mandatory_keys.select{|key|
      @answers[key].nil? or @answers[key].all?{ |v| v.empty? }
    }
  end

  def do_commit(req, res)
    answers = @answers.dup


    answers.select {|k, v| /\A.+?\*?_other\z/ =~ k}.each do |other_key, value|
      key = other_key.sub(/\*?_other\z/, '')
      if answers[key] && answers[key].any?
        # replace last value with hash which has a key corresponding 
        # to the last checked input and value of the last text input.
        # element as the value.
        answers[key] << {answers[key].pop => value.first }
      end
    end

    data = {
      :page_id => req.query["_page_id"].to_s,
      :answers => answers
    }

    save_post_data("enquete", req, data)

    render(@mobile, res, POST_HTML,
           :action => req.script_name,
           :back_uri => CONFIG[:enquete_uri_base] + req.query["_uri"])
  end

  def is_empty?(str)
    str =~ /\A\s*\z/m
  end

  def render_edit(res)
    render_raw(@mobile, res, prevalued_src)
  end

  def render_warning(res)
    render_raw(@mobile, res, emphasized_src)
  end

  def render_confirm(res, body)
    render_raw(@mobile, res, create_confirmation_page)
  end

  def prevalued_src
    html = @page_src.dup
    apply_answers!(html)
    enable_answered_other_input!(html)
    html
  end

  def enable_answered_other_input!(html)
    html.gsub!(/<input[^>]*?name="[^"]*?_other"[^>]*? \/>/) do |s|
      s.match(/value="[^"]+"/) ? s.sub('disabled', '') : s
    end
  end

  def emphasized_src
    html = prevalued_src
    missing_keys.each {|key|
      html.sub!(/<(?:input|textarea)[^>]*name="#{Regexp.quote(key)}\*"/,
                   '<strong style="color:red">必須入力です</strong><br />\&')
    }
    # Add a notification tag on the page top.
    html.sub!(/<form[^>]*?action="#{Regexp.escape(@cgi_uri)}"/, '<p style="padding: 10px; color:red; border:2px inset red;">※入力されていない箇所があります。</p>\&')
  end

  def apply_answers!(html)
    uncheck_checkbox_and_radio!(html)
    @answers.each {|key, val|
      key_re = Regexp.quote(key) + '\*?'
      val_re = Regexp.union(*val)
      html.gsub!(/<textarea[^>]*name="#{key_re}"[^>]*>/) {|s|
        apply_answer_to_textarea(s, val.first)
      } ||
      html.gsub!(/<input name="#{key_re}"[^>]*type="text"[^>]*?>/){|s| 
        apply_answer_to_text(s, val.first)
      } ||
      html.gsub!(/<input[^>]*(?:name="#{key_re}"[^>]*?value="#{val_re}"|value="#{val_re}"[^>]*?name="#{key_re}")[^>]*?>/) {|s|
        apply_answer_to_radio_or_checkbox(s)
      }
    }
  end

  def uncheck_checkbox_and_radio!(form)
    form.gsub!(/\s*checked\s*=\s*"checked"\s*/, ' ')
  end

  def apply_answer_to_radio_or_checkbox(s)
    s.sub(/\s*\/?>\z/, ' checked="checked"\&')
  end

  def apply_answer_to_text(s, value)
    s.sub( /value="/, '\&' + WEBrick::HTMLUtils.escape(value) )
  end

  def apply_answer_to_textarea(s, value)
    s + WEBrick::HTMLUtils.escape(value)
  end

  def create_confirmation_page
    html = @page_src.dup
    html.sub!(/<form[^>]+?action="#{Regexp.escape(@cgi_uri)}"[^>]*?>(.*?)<\/form>/m) do |s|
      [confirmation_page_title, create_confirm_form($1), create_commit_form].join("\n")
    end
    html
  end

  def create_confirm_form(html)
    str = html.dup
    apply_answers!(str)
    replace_form_control!(str)
    str
  end

  def replace_form_control!(str)
    control_replace_tab = [ [/<input[^>]*?type="(?:checkbox|radio)"[^>]*?>/,
                             lambda { |s| 
                               s.match(/checked="checked"/) ? 
                                 '<img src="/images/checkbox_checked.gif" alt="選択" />' : 
                                 '<img src="/images/checkbox_notchecked.gif" alt="未選択" />' 
                            }],
                            [/<input[^>]*?type="hidden"[^>]*?>/,
                             lambda { |s| }],
                            [/<input[^>]*?type="submit"[^>]*?>/,
                             lambda { |s| }],
                            [/<input[^>]*?type="text"[^>]*?>/,
                             lambda { |s| 
                              value  = s.slice(/value="([^"]*?)"/, 1)
                              "<div style=\"width: 50em; height: 1.5em; border: 2px inset #999;\">#{value}</div>"
                              }],
                            [/<textarea[^>]*?[^>]*?>(.*?)<\/textarea>/m,
                             lambda { |s| 
                              "<div style=\"width: 80%; height: 8em; overflow: auto; border: 2px inset #999;\">#{$1}</div>"
                             }] ]
    control_replace_tab.each do |re, replace_proc|
      str.gsub!(re, &replace_proc)
    end
    str.strip!
  end

  def create_commit_form
    <<FORM
<form method="post" action="#{@cgi_uri}">
<input type="hidden" name="_page_id" value="#{@page_id}" />
<input type="hidden" name="_uri" value="#{@page_uri}" />
#{create_hidden_answers}
<input name="_reedit" type="submit" value="アンケート画面に戻る" />
<input name="_commit" type="submit" value="送信" />
</form>
FORM
  end

  def create_hidden_answers
    @answers.map do |key, values|
      values.map do |value|
        %{<input name="#{key}" value="#{WEBrick::HTMLUtils.escape(value.to_s)}" type="hidden" />}
      end
    end.flatten.join("")
  end

  def confirmation_page_title
    %{<h1>入力確認画面</h1>}
  end

  def page_title
    "フォームの送信"
  end

  def send_mail_data
    key, value = @answers.detect { |k,| k =~ MAILMAGAZINE_REGEXP }
    to, body = key.split(/:/)
    from = value

    mail = TMail::Mail.new
    mail.to = to
    mail.from = from
    mail.subject = body
    mail.date = Time.now
    mail.mime_version = '1.0'
    mail.set_content_type 'text', 'plain', {'charset'=>'iso-2022-jp'}
    mail.body = body
    Net::SMTP.start(SERVER) do |smtp|
      smtp.sendmail(mail, from, to)
    end
  end

  def error_log(str)
    STDERR.puts(NKF.nkf('-w -m0', str))
  end
end

if __FILE__ == $0
cgi = EnqueteCGI.new
cgi.start
cgi.send_mail_data if cgi.mail_form?
end
