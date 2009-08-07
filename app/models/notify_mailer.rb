class NotifyMailer < ActionMailer::Base
  URL = "#{CMSConfig[:mail_uri]}_admin/show_page_info/"
  DOMAIN = "@#{CMSConfig[:mail_domain]}"

  ActionMailer::Base.server_settings = CMSConfig[:mail_config]

  def status_mail(section, page_content_id, from, to, subject)
    page = PageContent.find(page_content_id)
    create_mail_body(section, page, subject, from, to)
  end

  # 県TOP新着掲載
  def top_news_status_mail(section, page_content_id, from, to, subject)
    page = PageContent.find(page_content_id)
    create_mail_body(section, page, subject, from, to)
  end

  # page cancel request mail
  def cancel_request(section, page_content_id, from, to, subject = nil)
    page = PageContent.find(page_content_id)
    from = CMSConfig[:super_user_mail]
    subject = "ページ公開停止依頼"
    create_mail_body(section, page, subject, from, to)
  end

  # page enquete answer update notify mail
  def enquete_answer_exist(section, page_content_id, from, to, subject = nil)
    page = PageContent.find(page_content_id).page
    from = CMSConfig[:super_user_mail]
    subject = "CMS : アンケート受信のお知らせ"
    url = CMSConfig[:public_uri] + page.path.sub(/^\//,'')
    @subject = mime_encode("#{subject}")
    @from = CMSConfig[:super_user_mail]
    @recipients = to
    @sent_on    = Time.now
    body(:section => section, :page => page, :url => url)
  end

  # expired advertisement notify mail
  def expired_advertisement_exist(advertisement)
    subject = "CMSバナー広告掲載処理"
    @subject = mime_encode("#{subject}")
    @from = User::SUPER_USER_MAIL
    @recipients = User::SUPER_USER_MAIL
    @sent_on    = Time.now
    body(:name => advertisement.name)
  end

  def create! (*)
    super
    @mail.body = NKF::nkf('-j', @mail.body)
    return @mail
  end

  private

  def mime_encode(string)
    return NKF.nkf('-EjM', NKF.nkf('-We', string))
  end

  def create_mail_body(section, page_content, subject, from, to)
    @subject = mime_encode("CMS #{subject}(#{page_content.page.title})")
    section_manager = section.users.select{|i| i.authority == 1}
    if to.class == Array && to.size > 1
      @recipients = to.join(",")
    else
      @recipients = to
    end
    @from       = from
    @sent_on    = Time.now
    @headers    = {}
    user_name = page_content.user_name
    tel = page_content.tel
    email = page_content.email
    time = @sent_on.strftime('%Y年%m月%d日')
    begin_date = page_content.begin_date.strftime('%Y年%m月%d日 %H:%M') rescue nil
    end_date = page_content.end_date.strftime('%Y年%m月%d日 %H:%M') rescue nil
    comment = page_content.comment
    url = URL + page_content.page_id.to_s
    body(:section => section, :page_id => page_content.page_id,
         :user_name => user_name,
         :tel => tel, :email => email, :time => time,
         :begin_date => begin_date, :end_date => end_date,
         :comment => comment, :url => url,
         :status => subject)
  end
end
