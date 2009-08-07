# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def popup_link_to(name, options = {}, html_options = {}, *parameters_for_method_reference)
    url = url_for(options)
    html_options = html_options.merge(:onclick => "window.open('#{escape_javascript(url)}', '', 'toolbar=yes,status=no,menubar=yes,scrollbars=yes,resizable');return false;")
    link_to(name, options, html_options, parameters_for_method_reference)
  end

  def switch_radio_datetime_select(object, method, options = {})
    a = datetime_select(object, method, options).gsub(/<select/, "<select id=\"public_term_begin_date\" onclick=\"select_switch_radio('on');\"")
    ary = []
    a.split("\n").each do |i|
       if i =~ /\(\di\)/
         count = $&
         if i =~ /private\[begin_date/
           str = i.gsub(/id=\"public_term_begin_date\"/, "id=\"public_term_begin_date_#{count}\"")
         else
           str = i.gsub(/id=\"public_term_begin_date\"/, "id=\"public_term_end_date_#{count}\"")
         end
         ary << str
      else
        ary << i
      end
    end
    ary.join("\n")
  end

  def collection_radio_button(object, method, collection, value_method, text_method, options = {})
    join_val = options.delete(:join) || "\n"
    collection.collect{|i|
      radio_button(object, method, i.send(value_method), options) + h(i.send(text_method))
    }.join(join_val)
  end

  def collection_check_box(object, name, collection, value_method, text_method, options = {})
    join_val = options.delete(:join) || "\n"
    ret = %Q|<input name="#{object}[#{name}][]" type="hidden" value="">|
    ret << checkboxes = collection.collect{|i|
    obj = instance_variable_get("@#{object}")
    checked = (obj.send(name) || '').include?(i[0]) ? 'checked' : ''
    %Q|<input id="#{object}_#{name}" name="#{object}[#{name}][]" type="checkbox" value="#{h i[0]}" #{checked}>#{h i[1]}|
    }.join(join_val)
  end

  def news_strftime(time)
    time.strftime('%_m月%_d日') rescue '?月?日'
  end

  def public_term_strftime(time)
    time.strftime('%Y年%m月%d日 %H時%M分') rescue ''
  end

  def plugin(method, *args)
    @args = args
    begin
      render("plugin/#{method}")
    rescue
      raise $!
    end
  end

  def user
    @session[:user]
  end

  def admin?
    @admin_status = @user.authority == User::SUPER_USER if @admin_status.nil?
    @admin_status
  end

  def pagination_menu(pages, options = {})
    s = ""
    if pages.current.previous
      s << " " + link_to('前へ', options.update(:page => pages.current.previous))
    end
    if tmp = pagination_links(pages, :params => options)
      s << " " + tmp
    end
    if pages.current.next
      s << " " + link_to('次へ', options.update(:page => pages.current.next))
    end
    return '<p class="pagination_menu">' + s + '</p>'
  end

  def news_pagination_menu(pages)
    return (1..pages.page_count).collect {|i|
      if i == pages.current.number
        "#{i}"
      else
        %Q!<a href="/news.#{i}.html">#{i}</a>!
      end
    }.join(" ")
  end

  def enquete?
    /<%=\s*plugin\(\s*'form_/ =~ @content
  end

  def format_address(str)
    str.collect{|i|
      h(i).gsub(/[A-Za-z0-9;\/?:&=+$,\-_.!~*\'()#%]+@#{Regexp.quote(CMSConfig[:mail_domain])}/, '<a href="mailto:\&">\&</a>')
    }.join('<br />')
  end

  def image_tag(source, options = {})
    super unless @mobile
  end

  def rubi?
    @cookies['ruby'] && @cookies['ruby'].first == 'on'
  end

  def annotated_select_datetime(date,options={})
   [select_year(date, options) + '年',
    select_month(date, options) + '月',
    select_day(date, options) + '日',
    select_hour(date, options) + '時',
    select_minute(date, options) + '分'].join(' ')
  end

  def help_link(action_name, controller_name = nil)
    help_category_id = HelpAction.help_check(action_name, controller_name)
    if help_category_id
      "[#{link_to('ヘルプ', {:controller => 'help', :action => 'index', :category_id => help_category_id}, :popup => true)}]"
#      "[<a href=\"javascript:;\" onclick=\"window.open('#{CMSConfig[:mail_uri]}_help/index/?category_id=#{help_category_id}', 'help', 'left=0,top=0,width=1024,height=768,status=0,scrollbars=1,menubar=1,location=0,toolbar=1,resizable=1');\">ヘルプ</a>]"
    end
  end
end
