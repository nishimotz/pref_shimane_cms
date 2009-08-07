require 'filter'
require 'cleanup_html'

class PageContent < ActiveRecord::Base
  NEWS_NO = 0
  NEWS_YES = 1
  NEWS_REQUEST = 2
  NEWS_REJECT = 3

  SECTION_NEWS_NO = 0
  SECTION_NEWS_YES = 1

  EDITING = 0
  PUBLISH_REQUEST = 1
  PUBLISH_REJECT = 2
  PUBLISH = 3
  CANCEL = 4

  STATUS = {
    EDITING => '編集中',
    PUBLISH_REQUEST => '公開依頼',
    PUBLISH_REJECT => '却下',
    PUBLISH => '公開中',
    CANCEL => '公開停止',
  }

  PRIVATE_STATUS_LIST = {
    User::USER => [EDITING, PUBLISH_REQUEST],
    User::SECTION_MANAGER => [EDITING, PUBLISH_REQUEST, PUBLISH_REJECT, PUBLISH],
    User::SUPER_USER => [EDITING, PUBLISH_REQUEST, PUBLISH_REJECT, PUBLISH]
  }

  PUBLIC_STATUS_LIST = {
    User::USER => [],
    User::SECTION_MANAGER => [PUBLISH, CANCEL],
    User::SUPER_USER => [PUBLISH, CANCEL]
  }

  RSS_REGEXP = /^.*(plugin\('news|plugin\('genre_news_list|plugin\('section_news|plugin\('section_news_by_path).*$/

  belongs_to(:page)
  has_many(:links, :class_name => 'PageLink', :dependent => true)

  def self.skip_callback(callback)
    module_eval do
      method = instance_method callback
      remove_method callback if respond_to? callback
      define_method callback do; end
      logger.info("Skipping callback: #{callback.to_s}")
      yield
      remove_method callback
      define_method callback, method
    end
  end

  def section_news_message
    section_news == NEWS_YES ? 'する' : 'しない'
  end

  def top_news_message
    if admission == PUBLISH
      case top_news
      when NEWS_YES
        'する'
      when NEWS_NO
        'しない'
      when NEWS_REQUEST
        '依頼中'
      when NEWS_REJECT
        '却下'
      end
    else
      case top_news
      when NEWS_NO
        '依頼しない'
      else
        '依頼する'
      end
    end
  end

  def validate
    if self.begin_date && self.end_date
      unless Date.valid_date?(self.begin_date.year, self.begin_date.month, self.begin_date.day)
        errors.add(:begin_date, '開始日時に存在しない日を設定しています')
      end
      unless Date.valid_date?(self.end_date.year, self.end_date.month, self.end_date.day)
        errors.add(:end_date, '終了日時に存在しない日を設定しています')
      end
    end
  end

  def validate_title
    flag = []
    pages = Page.find(:all, :conditions => ["genre_id = ?",
                                            self.page.genre_id])
    unless pages.empty?
      pages.each do |page|
        if page.id != self.id && page.private.title == self.title
          flag << false
        end
      end
    end
    !flag.empty?
  end

  def content
    beautify_html(super || '')
  end

  def validate_content(conv = false)
    self.content = _validate_content(self.content || '', conv)
    return errors.empty?
  end

  def validate_mobile_content(conv = false)
    self.mobile = _validate_content(self.mobile || '', conv)
    return errors.empty?
  end

  def validate_news_title
    conv = false
    text2 = Filter::convert_non_japanese_chars(news_title, conv)
    invalid_chars = text2.scan(%r!<span\s*class="invalid"\s*>(.+?)</span\s*>!).collect{|i,| i}.uniq
    unless invalid_chars.empty?
      errors.add(:news_title, "次の文字は機種依存文字です。" + "(" + invalid_chars.join('、') + ")")
     strings = "#{invalid_chars.join('、')}"
    end
    return strings
  end

  def missing_internal_links
    warn = []
    err = []
    self.links.collect{|i| i.link}.uniq.each do |e|
      next unless %r!\A/.*(/|\.html)$! =~ e
      next if %r!/[^/]+\.data/! =~ e
      next if %r!/\z! =~ e && Genre.find_by_path(e)
      page = Page.find_by_path(e)
      if page.nil?
        err << e
      elsif page.current.nil?
        warn << e
      end
    end
    return [warn, err]
  end

  def mobile
    beautify_html(super || '')
  end

  def remove_tags_for_import
    cleanup_html
    str = self.content
    orig = str.dup
    return orig
  end

  def date
    self.begin_date || self.last_modified
  end

  def cleanup_html(str = self[:content])
    # remove script tags and script attributes
    str.gsub!(%r!<(script)\b.*</\1>!m, '')
    str.gsub!(%r!(<[^>]*) on[a-z]+="[^"]*"([^>]*>)!, '\1\2')

    # remove basefont tags
    str.gsub!(%r!<(/?)basefont\b[^>]*>!m, '')

    # remove img border
    str.gsub!(%r!(<img[^>]*) border=".*?"!, '\1')

    # remove font tags
    str.gsub!(%r!<(/?)font\b[^>]*>!m, '')

    # remove target attributes
    str.gsub!(%r!(<[^>]*) target="[^"]*"([^>]*>)!, '\1\2')

    # remove iframe tags
    str.gsub!(%r!<(iframe)\b.*</\1>!m, '')

    # remove frameset, frame, noframe tags
    str.gsub!(%r!<(/?)(?:frameset|frame|noframe)\b[^>]*>!m, '')

    # remove mce* class attributes
    str.gsub!(%r!(<[^>]*?)\s*class="mce\w*"([^>]*>)!, '\1\2')

    # remove mce* attributes
    str.gsub!(%r!(<[^>]*?)\s*mce_\w+="[^"]*"([^>]*>)!, '\1\2')

    # change align for table
#    str.gsub!(%r!(<table[^>]+?)\balign="([^"]*)"([^>]*>)(.*?</table>)!m, '<div class="table_div_\2">\1class="table_\2"\3\4</div>') # Version 1
#    str.gsub!(%r!(<table[^>]+?)\balign="([^"]*)"([^>]*>)(.*?</table>)!m, '\1\3\4') # Version 2

    # change align for some tables
#    str.gsub!(%r!(<table[^>]+?)\balign="([^"]*)"([^>]*>.*)(<table.*</table>)(.*?</table>)!m, '<div class="table_div_\2">\1class="table_\2"\3\4\5</div>') # Version NEW1
    # change align for one table
#    str.gsub!(%r!(<table[^>]+?)\balign="([^"]*)"([^>]*>)(.*?</table>)!m, '<div class="table_div_\2">\1class="table_\2"\3\4</div>') # Version NEW2
    
    #
    # wrap tables which have align attibute 
    #
    str.replace replace_align(str)

    # change align and valign attributes
    str.gsub!(%r!(<[^>]+?)\balign="([^"]*)"([^>]*>)!, '\1class="\2"\3')
    str.gsub!(%r!(<[^>]+?)\bvalign="([^"]*)"([^>]*>)!, '\1style="vertical-align: \2"\3')

    # change p to div in tables' parent nodes
    str.gsub!(%r!<p\b([^>]*?)>(\s*<table\b[^>]*?>.*?</table>\s*)</p>!im, '<div\1>\2</div>')

  end

  def replace_align(str)
    return str if str.empty?
    doc = HTree("<root>#{str}</root>").to_rexml
    root_node = doc.root
    root_node.wrap_align_table_with_div
    new_str = replace_plugin(doc.to_s.gsub(/\A<root>(.*)<\/root>\z/m, '\1'))
    restore_empty_tag(new_str)
  end
    
  def restore_empty_tag(str)
    #  
    # changes tag like <hoge /> to <hoge></hoge> except for <br /> tags.
    #
    # for example 
    #   restore_empty_tag(%Q!<a href="/kochokoho" /><br />)
    #    ==> <a href="/kochokoho"></a><br />
    #  
    str.gsub(%r%<(?!br|img|hr|input)([^>]+?)\b([^>]*?)\s*/>%, '<\1\2></\1>')
  end

  def normalize_html
    html = ''
    htree.display_xml(html)
    self.content = replace_plugin(html)
  end

  def normalize_mobile_html
    html = ''
    htree(self.mobile).display_xml(html)
    self.mobile = replace_plugin(html)
  end

  def replace_plugin(html)
    ret = html.dup
    ret.sub!(/\A.*?<body.*?>/m, '')
    ret.sub!(%r!</body.*\z!m, '')
    ret.gsub!(/&#39;/, "'")
    ret.gsub!(%r!(?:<p\b[^>]*>)?(?:&nbsp;)*&lt;%=\s*(plugin\(\s*'\w+'\s*(?:,\s*(?:'[^']+'|\d+)\s*)*\))\s*%&gt;(?:&nbsp;)*(?:</p\s*>)?!m, '<%= \1 %>')
    ret
  end

  def normalize_links
    path = URI.parse(page.genre.path)
    each_local_links do |uri|
      if uri.relative?
        uri = LOCAL_DOMAIN_URI + path + uri
      end
      uri.path.sub!(/\.html?$/i, '.html')
      uri.path.sub!(%r|/index\.html$|, '/')
      uri.scheme = nil
      uri.host = nil
      uri.to_s
    end
  end

  def replace_links(from, to)
    each_local_links do |uri|
      uri.to_s == from ? to : uri
    end
  end

  def replace_links_regexp(from, to)
    each_local_links do |uri|
      uri_s = uri.to_s
      if from =~ uri_s
        uri_s.sub(from, to)
      else
        uri
      end
    end
  end

  def each_local_links
    self.content = self.content.gsub(/(<[a-z]+\s+[^>]*?(?:href|src)=")([^"]+)/im) do |str|
      pre = $1
      uri = $2
      begin
        uri = URI.parse(uri)
        if local?(uri)
          uri = yield uri
        end
      rescue
      end
      "#{pre}#{uri}"
    end
    @htree = nil
  end

  def before_save
    normalize_html
    normalize_mobile_html
    normalize_links
    cleanup_html
    cleanup_html(self[:mobile]) if self.mobile
    set_links
  end

  def local_images
    images.select{|i| local?(i)}
  end

  def set_links
    links.clear
    # FIXME base_uri should be passed?
    htree.each_uri do |uri|
      next unless local?(uri)
      links << PageLink.new(:link => uri.to_s)
    end
  end

  def _local_links
    links.select{|i| local?(i)}
  end

  def images
    return @images if @images
    @images = []
    htree.traverse_element{|i|
      if i.qualified_name == 'img'
        images << URI.parse(i.get_attribute('src').to_s)
      end
    }
    @images
  end

  def mobile_content
    if self.mobile.blank?
      self.mobile = self.content
      mobile_remove_tag
    end
    return self.mobile
  end

  def mobile_remove_tag
    str = self.mobile
    str = remove_tags(str)
    str.gsub!(%r!<(/?)(?:img)\b[^>]*>!m, '')
    str.gsub!(/<!--.+?-->/, '')
    self.mobile = str
  end

  def status_message
    case self.admission
    when PUBLISH
      now = Time.now
      if self.begin_date && self.begin_date > now
        '公開待ち'
      elsif self.end_date && self.end_date < now
        '公開終了'
      elsif self.admission == CANCEL
        '公開停止'
      else
        '公開中'
      end
    else
      STATUS[self.admission]
    end
  end

  def public_term_enable?
    now = Time.now
    return false if end_date && end_date < now
    return false if begin_date && now < begin_date
    return true
  end

  def enquete_items
    content.scan(/<%=\s*plugin\(\s*'form_([^']*?)',\s'([^']*?)\*?'(?:,\s('.*?))?\)\s*%>/m).
      map do |item|
        type, name, values =  item
        {:type => type,
         :name => name,
         :values => (values.scan(/'([^\']*?)'/).flatten if values)}
    end
  end

  def publish
    if !(waiting_page = self.page.waiting_page) or self == waiting_page
      # destroy cancel_page jobs yet to be done by the newly set begin_date.
      Job.destroy_all(['action = ? AND arg1 = ? AND datetime >= ?',
                     'cancel_page', page.id, self.begin_date || Time.now])
      # destroy remainig create jobs.
      Job.destroy_all(['action = ? AND arg1 = ? AND datetime <= ?',
                     'create_page', page.id, Time.now])
    else
      Job.destroy_all(['action = ? AND arg1 = ? AND datetime >= ? AND NOT datetime = ?',
                     'cancel_page', page.id, self.begin_date || Time.now, waiting_page.end_date])
      Job.destroy_all(['action = ? AND arg1 = ? AND datetime <= ? AND NOT datetime = ?',
                     'create_page', page.id, Time.now, waiting_page.begin_date])
    end

    Job.create(:action => 'create_page',
               :arg1 => self.page_id,
               :datetime => self.begin_date || Time.now)
    Job.create(:action => 'cancel_page',
               :arg1 => self.page_id,
               :datetime => self.end_date) if self.end_date
  end

  private

  def _validate_content(text, conv)
    text.gsub!(/<!--.*?-->/, '')
    text.gsub!(%r!<span[^>]*?\s*class="invalid"[^>]*>([^<]+)</span\s*>!, '\1')
    text.gsub!(%r!<img([^>]*?)\s*class="invalid"!, '<img\1')
    text2 = Filter::convert_non_japanese_chars(text, conv)
    if conv && text != text2
      converted_chars = text.scan(Regexp.union(*Filter::CONV_TABLE.keys)).uniq
      converted_chars = converted_chars.collect do |e|
        "#{e}→#{Filter::CONV_TABLE[e]}"
      end
      errors.add(:conv_char, "機種依存文字を変換しました：#{converted_chars.join('、')}") unless converted_chars.empty?
    end
    invalid_chars = text2.scan(%r!<span\s*class="invalid"\s*>(.+?)</span\s*>!).collect{|i,| i}.uniq
    unless invalid_chars.empty?
      if conv
        errors.add(:char, "変換できない機種依存文字があります：#{invalid_chars.join('、')}")
      else
        errors.add(:char, "機種依存文字があります：#{invalid_chars.join('、')}")
      end
    end
    text3 = text2.gsub(%r!<img(\s*[^>]*)>!) {|img|
      img_attr = $1
      if /\salt="[^"]*"\s/ =~ img
        img
      else
        %Q!<img class="invalid"#{img_attr}>!
      end
    }
    errors.add(:alt, '「画像の説明」のない画像があります') unless text2 == text3
    return text3
  end

  def local?(uri)
    (uri.relative? && !uri.path.empty?) || (uri.scheme == 'http' && LOCAL_DOMAINS.include?(uri.host))
  end

  def htree(text = self.content)
    body = text || ''
    body = "<html><body>#{body}</body></html>" unless body.match(/<body[^>]*>/im)
    return HTree.parse(body)
  end

  def remove_tags(str)
    ret = str.dup
    # remove table, tr tags
#    ret.gsub!(%r!</?(?:table|tr)\b[^>]*>!m, '')

    # replace td, th tags to div
#    ret.gsub!(%r!<(/?)(?:td|th)\b[^>]*>!m, '<\1div>')

    # remove class, style, align attributes
    ret.gsub!(%r!(<[^>]*) (?:class|style|align)="[^"]*"([^>]*>)!, '\1\2')

    # remove font, span tags
    ret.gsub!(%r!<(/?)(?:font|span)\b[^>]*>!m, '')

    return ret
  end

  def beautify_html(str)
    str.gsub(/\r?\n/, '').gsub(%r!\s*/>!, ' />').gsub(%r!</(?:blockquote|dd|div|dl|dt|form|h[1-6]|hr|li|ol|p|pre|table|tbody|td|tfoot|th|thead|tr|ul)>!, "\\&\n").gsub(%r!<(?:dl|ol|table|tbody|tfoot|thead|tr|ul)\b[^>]*>!, "\\&\n")
  end
end
