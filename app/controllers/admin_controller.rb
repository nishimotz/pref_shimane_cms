require 'open-uri'
require 'fileutils'
require 'rubi_adder'
require 'tempfile'

class AdminController < ApplicationController
  layout('admin', :except => 'list_file')
  before_filter(:authorize, :except => [:login, :logout, :show_info_content])
  before_filter(:prepare_user)
  before_filter(:authorize_admin, :only => [:list_section, :section_search, :show_section, :new_section, :create_section, :edit_section, :update_section, :destroy_section, :list_info, :show_info, :new_info, :create_info, :edit_info, :update_info, :destroy_info, :list_user, :edit_user, :update_user, :new_user, :create_user, :destroy_user, :update_genre_section])
  before_filter(:authorize_section_manager, :only => [:move, :edit_section_info, :private_page_unlock])
  after_filter(:rubi_filter, :only => [:update_page, :show_template])

  include(LoginHelper)

  FILE_PATH = "#{RAILS_ROOT}/files/#{RAILS_ENV}"
  EXT_RE = /\A\.(doc|xls|jaw|jbw|jfw|jsw|jtd|jtt|jtw|juw|jvw|pdf|jpe?g|png|gif|mp3|wav|mpe?g|rm|rmvb|rtf|kml|csv|tsv|txt)\z/i
  EXT_ZIP = /\A\.(zip)\z/i

  # menu methods
  def index
    @mode = :home
  end

  def page
    show_genre
    @action = :page
    @mode = :page
  end

  def genre
    show_genre
    @action = :genre
    @mode = :genre
  end

  def config
    @action = :config
    @mode = :config
  end

  # page
  def new_page
    show_genre
    @action = :new_page
    @mode = :page
    @template_list = Genre.find(:first, :conditions => ['path = ?', '/template/']).pages.collect{|i| [i.title, i.id]}
  end

  def create_page
    prepare_genre
    id = params[:id]
    @page = Page.new(:name => params[:page][:name],
                     :title => params[:page][:title],
                     :genre_id => id)
    page = @page
    invalid_char = @page.validate_page_title
    if invalid_char && invalid_char != ""
      flash[:title_notice] = "次の文字は機種依存文字です。" + "(" + invalid_char + ")"
      new_page
      @page = page
      render(:action => 'new_page', :id => params[:id])
      return
    end

    if @page.save
      @page = Page.find(@page.id)
      @content = @page.private
      @content.content = Page.find(params[:template]).private.content if params[:template_page][:enable] == "on"
      @content.save
      redirect_to(:action => 'edit_page', :id => @page, :status => 'new')
    else
      flash[:name_notice] = @page.errors[:name]
      flash[:title_notice] = @page.errors[:title]
      @action = :new_page
      @mode = :page
      @template_list = Genre.find(:first, :conditions => ['path = ?', '/template/']).pages.collect{|i| [i.title, i.id]}
      render(:action => 'new_page', :id => params[:id])
    end
  end

  def edit_title
    @mode = :info
    @action = :edit
    prepare_page
  end

  def update_title
    if params[:cancel]
      redirect_to(:action => 'show_page_info', :id => params[:id])
      return
    end
    prepare_page
    @page.title = params[:page][:title]

    invalid_char = @page.validate_page_title
    if invalid_char && invalid_char != ""
      @page.errors.add(:title, "次の文字は機種依存文字です。" + "(" + invalid_char + ")")
      render(:action => 'edit_title', :id => params[:id])
      return
    end

    if @page.save
      redirect_to(:action => 'show_page_info', :id => @page)
    else
      @page.title = params[:page][:title]
      render(:action => 'edit_title')
    end
  end

  def edit_page
    @action = :edit
    @mode = :page
    prepare_page
    return unless page_status_check
    lock_page(@page)
    @content = @page.private
    @content.content = (@content.content || '').gsub(/<%/, '&lt;%').gsub(/%>/, '%&gt;')
    @content.content = @content.content.gsub(%r!(<[^>]+?)\bclass="(left|center|right)"([^>]*>)!, '\1align="\2"\3')
    @content.content = @content.content.gsub(%r!(<[^>]+?)\bstyle="vertical-align: ([^"]*)"([^>]*>)!, '\1valign="\2"\3')

    @content.content = @content.content.gsub(%r!(<div[^>]+?)\bclass="table_div_(left|center|right)"([^>]*>)(<table[^>]+?)\bclass="table_(left|center|right)"([^>]*>)!, '\4align="\5"\6')
  end

  def private_page_unlock
    page = Page.find(params[:id])
    unlock_page(page)
    redirect_to(:action => 'show_page_info', :id => params[:id])
  end

  def edit_mobile_page
    @action = :edit
    @mode = :mobile
    prepare_page
    @content = @page.private
    @content.mobile = (@content.mobile || '').gsub(/<%/, '&lt;%').gsub(/%>/, '%&gt;')
  end

  def show_page_info
    @mode = :info
    prepare_page
    if page_locked_by_others?(@page)
      @action = :cannot_edit
      @lock = true
      return
    end
    @lock = false
    @waiting = @page.waiting_page
    @admitting = @page.admitting_page
    if @waiting || (@admitting && @user.authority == User::USER)
      @action = :cannot_edit
    end
  end

  def page_cancel_request
    begin
      page = Page.find(params[:id])
      public = page.public_page
      to_address = page.genre.section.users.select{|i| i.authority == User::SECTION_MANAGER}.collect{|i| i.mail}
      email = NotifyMailer.create_cancel_request(@user.section, public.id,
                                                 '', to_address, '')
      NotifyMailer.deliver(email)
      flash[:error] = '公開停止依頼を行いました。'
      redirect_to(:action => 'show_page_info', :id => page)
    rescue
      redirect_to(:action => 'show_page_info', :id => page)
    end
  end

  def show_page
    @mode = :page
    prepare_page
    @private = @page.private
    @public = @page.public
    @preview = true
  end

  def edit_private_page_status
    @action = :edit
    @mode = :info

    @private = PageContent.find(params[:id])
    @page = @private.page
    @genre = @page.genre
    page_permission_check

    @private.news_title = @page.title if @private.news_title.blank?
    @private.section_news = PageContent::NEWS_YES if @private.section_news.blank?
    @private_status_list = PageContent::PRIVATE_STATUS_LIST[@user.authority].collect{|i| [i, PageContent::STATUS[i]]}
  end

  def edit_public_page_status
    @action = :edit
    @mode = :info

    # edit_private_page_status
    @public = PageContent.find(params[:id])
    @page = @public.page
    @genre = @page.genre
    page_permission_check

    if @public.begin_date && @public.begin_date > Time.now
      @public_status_list = [[PageContent::PUBLISH, '承認'], [PageContent::PUBLISH_REJECT, '却下']]
    else
      @public_status_list = PageContent::PUBLIC_STATUS_LIST[@user.authority].collect{|i| [i, PageContent::STATUS[i]]}
    end
  end

  def admission_top_news
    public = PageContent.find(params[:id])
    page = public.page
    page_permission_check(page)

    if params[:cancel]
      redirect_to(:action => 'show_page_info', :id => page)
      return
    end

    if params[:reject]
      public.top_news = PageContent::NEWS_REJECT
      public.comment = params[:public][:comment]
      public.save
      redirect_to(:action => 'show_page_info', :id => page)
      send_mail(public, PageContent::NEWS_REJECT, true)
      return
    end
    public.top_news = PageContent::NEWS_YES
    public.comment = params[:public][:comment]
    public.save
    News.create(:page_id => page.id,
                :title => public.news_title,
                :published_at => public.date)
    send_mail(public, PageContent::NEWS_YES, true)
    Job.create(:action => 'create_page',
               :arg1 => Page.find_by_path('/index.html').id,
               :datetime => Time.now)
    redirect_to(:action => 'show_page_info', :id => page)
  end

  def show_template
    @content = Page.find(params[:id]).private.content
    @genre = Genre.find(params[:genre_id])
    title = params[:title].blank? ? '無題' : params[:title]
    @page = Page.new(:genre_id => @genre.id,
                     :name => params[:name],
                     :title => title)
    @layout = layout(@page.name)
    @preview = true
    render(:action => '../visitor/page', :layout => false)
  end

  def update_page
    @page = Page.find(params[:id])
    return unless page_status_check
    if params[:cancel]
      genre_id = @page.genre_id
      if params[:status] == 'new'
        @page.destroy
        redirect_to(:action => 'index')
      else
        unlock_page(@page)
        redirect_to(:action => 'show_page_info', :id => @page)
      end
    else
      page_permission_check
      @content = @page.private
      @content.attributes = params[:content]
      if params[:preview]
        @genre = @page.genre
        @layout = layout(@page.name)
        case @page.name
        when 'index'
          if @genre.path == '/'
            @layout = :top_layout
          elsif Section.find(:first, :conditions => ['top_genre_id = ?', @page.genre_id])
            @layout = :section_top_layout
          else
#            ancestors = @genre.ancestors
#            if ancestors.size > 3
              @layout = :normal_layout
#            else
#              genres = ancestors.select{|i| Section.top_genre_ary.index(i.id) }
#              if genres
#                @layout = :normal_layout
#              else
#                @layout = :genre_top_layout
#              end
#            end
          end
        else
          @layout = :normal_layout
        end
        @content.normalize_html
        @content.normalize_links
        @content.cleanup_html
        @content.validate_content
        @content = @content.content
        @preview = true
        render(:action => "../visitor/" + @page.template, :layout => false)
        return
      elsif params[:convert_char]
        @content.validate_content(true)
        @action = :edit
        @mode = :page
        prepare_page
        render(:action => 'edit_page')
        return
      else
        unless @content.validate_content
          @action = :edit
          @mode = :page
          prepare_page
          render(:action => 'edit_page')
          return
        end
        # copy local link files
        @content.each_local_links do |uri|
          uri_s = uri.to_s
          if %r!([^.]+)\.data/([^/]+)\z! =~ uri_s
            link_path = $1
            file = $2
            if link_path != @page.path_base && link_page = Page.find_by_path("#{link_path}.html")
              begin
                dir = attach_dir(@page)
                FileUtils.cp("#{FILE_PATH}/#{link_page.id}/#{file}", dir,
                             :preserve => true)
              rescue
              end
              uri_s = "#{@page.path_base}.data/#{file}"
            end
          end
          uri_s
        end
        @content.admission = PageContent::EDITING
        @content.top_news = PageContent::NEWS_NO
        @content.section_news = PageContent::SECTION_NEWS_YES
        @content.last_modified = Time.now
        if @content.save
          unlock_page(@page)
          @page.add_revision(PageRevision.new(:last_modified => @content.last_modified, :user_id => @user.id))
          flash[:notice] = 'Page was successfully updated.'
          redirect_to(:action => 'show_page_info', :id => @page)
        else
          flash[:page_notice] = 'タイトルが入力されていません'
          prepare_page
          failure_edit_page
        end
      end
    end
  end

  def update_mobile_page
    @page = Page.find(params[:id])
    if params[:cancel]
      redirect_to(:action => 'show_page_info', :id => @page)
    else
      page_permission_check
      @content = @page.private
      @content.mobile = params[:content][:mobile]
      @content.mobile_remove_tag
      if params[:convert_char]
        @content.validate_mobile_content(true)
        @action = :edit
        @mode = :page
        prepare_page
        render(:action => 'edit_mobile_page')
        return
      elsif !@content.validate_mobile_content
        @action = :edit
        @mode = :page
        prepare_page
        render(:action => 'edit_mobile_page')
        return
      end
      @content.admission = PageContent::EDITING
      @content.mobile = (@content.mobile || '').gsub(/&lt;%/, '<%').gsub(/%&gt;/, '%>')
      if @content.save
        flash[:notice] = 'Page was successfully updated.'
        redirect_to(:action => 'show_page_info', :id => @page)
      else
        prepare_page
        failure_edit_page
      end
    end
  end

  def copy_to_mobile
    edit_mobile_page
    @content.mobile = @content.content
    @content.mobile_remove_tag
    @content.mobile = (@content.mobile || '').gsub(/<%/, '&lt;%').gsub(/%>/, '%&gt;')
    render(:action => 'edit_mobile_page', :id => @page)
  end

  def show_mobile_revision_page
    @mode = :mobile
    @private = PageContent.find(params[:id])
    @page = @private.page
    @genre = @page.genre
    @mobile = true
    @preview = true
    render(:action => :show_mobile_page)
  end

  def destroy_page
    prepare_page
    unless @page.destroyable?(@user)
      flash[:error] = '現在、ページの削除はできません。'
      redirect_to(:action => 'show_page_info', :id => @page)
      return
    end
    Job.create(:action => 'delete_page', :arg1 => @page.path,
               :datetime => Time.now)
    sn = SectionNews.find(:first, :conditions => ['page_id = ?', @page.id])
    sn.destroy if sn
    @page.destroy
    redirect_to(:action => 'index')
  end

  def destroy_public_term
    page_content = PageContent.find(params[:id])
    page = page_content.page
    page_permission_check(page)
    admission = page_content.admission
    waiting_page = page.waiting_page
    term_flag = page_content.public_term_enable?
    if page
      unless waiting_page
        Job.destroy_all(['action =? AND arg1 = ?', 'cancel_page', page.id])
      else
        unless page_content == waiting_page
          query = 'action = :action AND arg1 = :page_id AND NOT datetime = :datetime'
          Job.destroy_all([query,
                          {:action => 'cancel_page',
                           :page_id => page.id,
                           :datetime => waiting_page.end_date}])
        else
          Job.destroy_all(['(action = ? OR action = ?) AND arg1 = ?',
                           'create_page', 'cancel_page', page.id])
          Job.create(:action => 'create_page', :arg1 => page.id,
                     :datetime => Time.now)
          Job.find(:all, :conditions =>
                   ['action = ? AND arg1 = ? AND datetime = ?',
                    'enable_remove_attachment',
                    page.path_base + '.data/',
                    page_content.begin_date]).each do |job|
                      job.update_attribute(:datetime, Time.now)
                    end
        end
      end
      unless page_content == waiting_page
        if !term_flag and admission == PageContent::PUBLISH
          Job.create(:action => 'create_page',
                     :arg1 => page.id,
                     :datetime => Time.now)
        elsif term_flag and admission == PageContent::CANCEL
          Job.create(:action => 'create_page',
                     :arg1 => page.id,
                     :datetime => Time.now)
          page_content.update_attribute(:admission, PageContent::PUBLISH)
        end
      end
      page_content.update_attributes(:begin_date => nil, :end_date => nil)
      redirect_to(:action => 'show_page_info', :id => page)
    else
      raise 'ページが存在しません'
    end
  end

  def update_private_page_status
    @private = PageContent.find(params[:id])
    @page = @private.page
    page_permission_check

    if params[:cancel]
      redirect_to(:action => 'show_page_info', :id => @page)
      return
    end

    @private.admission = params[:private][:admission]
    @private.section_news = params[:private][:section_news]
    @private.top_news = params[:private][:top_news]
    if @private.admission == PageContent::PUBLISH
      @private.last_modified = Time.now
    end

    @private.news_title = params[:private][:news_title]

    if params[:private][:news_title].blank?
      # Do not consider the page as a news item if title is blank.
      @private.section_news = PageContent::SECTION_NEWS_NO
    end

    if @private && @private.news_title
      invalid_char = @private.validate_news_title
      private_dup = @private
      if invalid_char && invalid_char != ""
        edit_private_page_status
        @private = private_dup
        render(:action => 'edit_private_page_status', :id => params[:id])
        return
      end
    end

    # 公開期間設定
    if params[:public_term][:switch] == "on"
      private = params[:private]
      if params[:public_term][:end_date_enable] == 'on'
        @private.begin_date = Time.local(private['begin_date(1i)'].to_i,
                                         private['begin_date(2i)'].to_i,
                                         private['begin_date(3i)'].to_i,
                                         private['begin_date(4i)'].to_i,
                                         private['begin_date(5i)'].to_i)
        @private.end_date = Time.local(private['end_date(1i)'].to_i,
                                       private['end_date(2i)'].to_i,
                                       private['end_date(3i)'].to_i,
                                       private['end_date(4i)'].to_i,
                                       private['end_date(5i)'].to_i)
        if @private.begin_date > @private.end_date
          edit_private_page_status
          @error = '開始日時の指定が間違っています'
          render(:action => 'edit_private_page_status', :id => params[:id])
          return
        elsif @private.end_date < Time.now
          edit_private_page_status
          @error = '今日より古い期間が設定されています'
          render(:action => 'edit_private_page_status', :id => params[:id])
          return
        end
      else
        @private.begin_date = Time.local(private['begin_date(1i)'].to_i,
                                         private['begin_date(2i)'].to_i,
                                         private['begin_date(3i)'].to_i,
                                         private['begin_date(4i)'].to_i,
                                         private['begin_date(5i)'].to_i)
        @private.end_date = nil
      end
      unless @private.save
        flash[:public_term_notice] = @private.errors[:begin_date]
        edit_private_page_status
        render(:action => 'edit_private_page_status', :id => params[:id])
        return
      end
    else
      @private.begin_date = nil
      @private.end_date = nil
    end

    # メールアドレスのチェック
    if params[:private][:email] && params[:private][:email] =~ /@/
      @private.email = params[:private][:email]
      edit_private_page_status
      @error = 'Eメールの@以降は入力しないで下さい'
      render(:action => 'edit_private_page_status', :id => params[:id])
      return
    end

    @private.user_name = params[:private][:user_name]
    @private.tel = params[:private][:tel]
    @private.email = params[:private][:email]
    @private.comment = params[:private][:comment]
    @private.save
    # add a job
    if @private.admission == PageContent::PUBLISH
      # todo store to enquete_items table if enquete
      store_enquete_items(@private)
      @private.publish
      update_remove_attachment(@private)
    end
    send_mail(@private, params[:private][:admission])
    redirect_to(:action => 'show_page_info', :id => @page)
  end

  def update_public_page_status
    public = PageContent.find(params[:id])
    page = public.page
    page_permission_check(page)

    if params[:cancel]
      redirect_to(:action => 'show_page_info', :id => page)
      return
    end

    # メールアドレスのチェック
    if params[:public][:email] && params[:public][:email] =~ /@/
      public.email = params[:public][:email]
      edit_public_page_status
      flash[:notice_email] = 'Eメールの@以降は入力しないで下さい'
      render(:action => 'edit_public_page_status', :id => params[:id])
      return
    end

    public.user_name = params[:public][:user_name]
    public.tel = params[:public][:tel]
    public.email = params[:public][:email]
    public.comment = params[:public][:comment]
    unless public.begin_date
      public.last_modified = Time.local(params[:public]['last_modified(1i)'].to_i,
                                        params[:public]['last_modified(2i)'].to_i,
                                        params[:public]['last_modified(3i)'].to_i,
                                        params[:public]['last_modified(4i)'].to_i,
                                        params[:public]['last_modified(5i)'].to_i)
    end
    send_mail = false
    if public.last_modified > Time.now
      edit_public_page_status
      flash[:notice_last_modified] = '日時を現在より先の日時に設定されています。'
      render(:action => 'edit_public_page_status', :id => params[:id])
      return
    end

    new_admission = params[:public][:admission].to_i
    if public.admission != new_admission
      case new_admission
      when PageContent::PUBLISH
        # public.last_modified = Time.now
        public.publish
      when PageContent::PUBLISH_REJECT
        send_mail = true
        Job.destroy_all(['action =? and arg1 = ? and datetime =?',
                          'create_page', page.id, public.begin_date]) if public.begin_date
        Job.destroy_all(['action =? and arg1 = ? and datetime =?',
                          'cancel_page', page.id, public.end_date]) if public.end_date
        if (current = page.current) && current.end_date
          unless Job.find(:first, :conditions => ['action = ? AND arg1 = ? AND datetime = ?', 'cancel_page', page.id, current.end_date])
            Job.create(:action => 'cancel_page',
                       :arg1 => page.id,
                       :datetime => current.end_date)
          end
        end
      when PageContent::CANCEL
        unless waiting_page = page.waiting_page
          Job.destroy_all(['action =? AND arg1 = ? AND datetime =?',
                           'cancel_page', page.id, public.end_date]) if public.end_date
        else
          Job.destroy_all(['action =? AND arg1 = ? AND datetime =? AND NOT datetime = ?',
                           'cancel_page', page.id, public.end_date, waiting_page.end_date]) if public.end_date
        end
        Job.create(:action => 'cancel_page', :arg1 => page.id,
                   :datetime => Time.now)
      end
      public.admission = new_admission
    end
    public.save

    send_mail(public, public.admission) if send_mail

    redirect_to(:action => 'show_page_info', :id => page)
  end

  def reverse_status_to_edit
    page = Page.find(params[:id])
    @private = page.private
    @private = page.contents[0]
    @private.admission = PageContent::EDITING
    @private.save
    redirect_to(:action => 'show_page_info', :id => page)
  end

  def update_genre
    page = Page.find(params[:page_id])
    if page.genres.select { |i| i.genre_id == params[:id].to_i}.empty?
      page.genres << Genre.new("page_id" => page.id, "genre_id" => params[:id])
      page.save
    end
    redirect_to(:action => 'set_genre_page', :id => page)
  end

  def remove_genre
    genres = Genre.find(:first,
                        :conditions => ["page_id = ? and genre_id = ?",
                                        params[:page_id], params[:id]])
    genres.destroy
    redirect_to :action => 'set_genre_page', :id => params[:page_id]
  end

  def list_page_status
    @action = :info
    @mode = :info
    @genre_ids = @user.genres.collect{|i| i.id}
  end

  def find_by_path
    begin
      uri = URI.parse(params[:path])
      raise if uri.host && !LOCAL_DOMAINS.include?(uri.host)
      page = Page.find_by_path(uri.path)
      raise unless page
      redirect_to(:action => 'show_page_info', :id => page.id)
    rescue
      flash[:find_by_path_message] = '見つかりませんでした。'
      redirect_to(:action => 'page', :id => params[:id])
    end
  end

  # genre
  def show_genre
    @action = :genre
    @mode = :genre
    @page = Page.new
    prepare_genre
    @new_genre = Genre.new()
    setup_divisions
    setup_sections(@divisions.first[1])
  end

  def update_genre_section_options
    setup_divisions
    setup_sections(params[:genre_division_code])
    render(:partial => 'genre_section_list')
  end

  def sort_genre
    @action = :sort_genre
    @mode = :config
    prepare_genre
  end

  def update_sort_genre
    genre_permission_check(Genre.find(params[:id].to_i))
    @genres = []
    params[:list].each_with_index do |genre_id, i|
      @genres << Genre.update(genre_id.to_i, :no => i)
    end
    render(:partial => 'sort_genre')
  end

  def right_pain_change_for_page
    show_genre
    @action = :page
    @action_ajax = :right_pain_change_for_page
    @mode = :page
    render(:partial => 'page_list')
  end

  def right_pain_change_for_genre
    show_genre
    @action = :genre
    @action_ajax = :right_pain_change_for_genre
    @mode = :genre
    render(:partial => 'genre_info')
  end

  def right_pain_change_for_sort_genre
    @action = :sort_genre
    @mode = :config
    prepare_genre
    @action_ajax = :right_pain_change_for_sort_genre
    render(:partial => 'sort_genre_info')
  end

  def right_pain_change_for_new_page
    new_page
    render(:partial => 'new_page_info')
  end

  def right_pain_change_for_import_all
    import_all
    path = "#{Page::ZIP_FILE_PATH}/#{@user.section.id}"
    files = Dir.glob("#{path}/*.zip")
    if !files.empty?
      @path = files.first
      @file = @path.split('/').last
    elsif File.exist?("#{path}/error")
      @results = File.open("#{path}/error").readlines
    end
    render(:partial => 'import_all_form')
  end

  def move
    @action = :move
    @mode = :move
    prepare_genre
  end

  def move_partial
    @genre = Genre.find(params[:id])
    render(:partial => 'move')
  end

  def move_update
    from_id = params[:id].scan(/\d+/).first
    to_id = params[:recv].scan(/\d+/).first
    mode = params[:id].index('page') ? :page : :genre
    raise NotUpdateError unless from_id && to_id
    genre_to = Genre.find(to_id)
    if mode == :genre
      genre_from = Genre.find(from_id)
      genre_permission_check(genre_from)
      genre_permission_check(genre_to)
      if genre_edit_page_exists?(genre_from)
        flash[:page_editing_notice] = "移動するフォルダの中に未公開ページがあるため、フォルダの移動ができませんでした。未公開ページを公開してから、作業をやり直してください。"
        render(:nothing => true)
        return
      end
      unless genre_to.ancestors.include?(genre_from)
        new_path = "#{genre_to.path}#{genre_from.name}/"
        old_path = genre_from.path
        genre_from.parent_id = genre_to.id
        begin
          ActiveRecord::Base.transaction do
            if genre_from.save!
              Job.create(:action => 'move_folder', :arg1 => new_path,
                         :arg2 => old_path, :datetime => Time.now)
              move_genre(old_path, new_path)
            end
          end
        rescue => e
          logger.error(%Q|#{e.inspect}\n#{e.backtrace.join("\n")}|)
        end
      end
    else # :page
      page_from = Page.find(from_id)
      page_permission_check(page_from)
      genre_permission_check(genre_to)
      if page_under_edit?(page_from)
        flash[:page_editing_notice] = "未公開ページがあるため、ページの移動ができませんでした。未公開ページを公開してから、作業をやり直してください。"
        render(:nothing => true)
        return
      end
      new_path = page_from.path.sub(%r|^#{page_from.genre.path}|, genre_to.path)
      old_path = page_from.path
      page_from.genre_id = genre_to.id
      begin
        ActiveRecord::Base.transaction do
          if page_from.save!
            Job.create(:action => 'move_page', :arg1 => genre_to.path,
                       :arg2 => old_path, :datetime => Time.now)
            move_page(old_path, new_path)
          end
        end
      rescue => e
        logger.error(%Q|#{e.inspect}\n#{e.backtrace.join("\n")}|)
      end
    end
    render(:nothing => true)
  end

  def create_genre
    dir = Genre.find(params[:id])
    @new_genre = Genre.new(params[:new_genre])
    @new_genre.parent_id = dir.id
    @new_genre.section_id = dir.section_id

    invalid_char = @new_genre.validate_genre_title
    genre_dup = @new_genre
    if invalid_char && invalid_char != ""
      genre
      @new_genre = genre_dup
      render(:action => 'genre', :id => params[:id])
      return
    end

    if @new_genre.save
      @new_genre.add_genre_jobs
      redirect_to :action => 'genre', :id => params[:id]
    else
      @page = Page.new
      prepare_genre
      @sections = Section.find(:all, :order => 'number').collect { |i| [i.name, i.id] } if admin?
      @divisions = Division.find(:all, :conditions => ['enable = true'], :order => 'number').collect{|i| [i.name, i.id]}
      @action = :genre
      render(:action => 'genre', :id => params[:id])
    end
  end

  def edit_genre
    edit_genre = Genre.find(params[:id].to_i)
    edit_genre.title = params[:genre][:title]
    edit_genre.uri = params[:genre][:uri]

    invalid_char = edit_genre.validate_genre_title
    genre_dup = edit_genre
    if invalid_char && invalid_char != ""
      genre
      @genre = genre_dup
      render(:action => 'genre', :id => params[:id])
      return
    end

    if edit_genre.save
      edit_genre.add_genre_jobs
      flash[:notice_update_folder] = 'フォルダの名前を変更しました。'
      redirect_to :action => 'genre', :id => params[:id]
    else
      show_genre
      @dir = edit_genre
      @genre = edit_genre
      render(:action => 'genre', :id => params[:id])
    end
  end

  def destroy_genre
    genre = Genre.find(params["id"])
    genre_id = genre.id
    parent_id = genre.parent.id
    unless genre.destroyable?(@user)
      flash[:update_notice] = 'フォルダの削除はできません。'
      redirect_to(:action => 'genre', :id => genre_id)
      return
    end
    if genre.destroy
      if genre.section.top_genre_id &&
           genre_id == genre.section.top_genre_id
        genre.section.update_attributes(:top_genre_id => nil)
      end
      flash[:update_notice] = "フォルダ[#{genre.title}]を削除しました"
      redirect_to :action => 'genre', :id => parent_id
    else
      flash[:update_notice] = 'failure genre destroy.'
      render('genre')
    end
  end

  def update_genre_section
    genre = Genre.find(params[:id])
    genre.section = Section.find(params[:genre][:section_id])
    if genre.save
      redirect_to :action => 'genre', :id => params[:id]
    else
      flash[:update_notice] = '所属の変更ができませんでした'
      genre
      render('genre')
    end
  end

  def search_genre
    @genres = Genre.find(:all,
                        :conditions => ['uri = ?', params[:uri]])
    render(:partial => 'search_genre')
  end

  def set_tracking_code
    if params[:id] && Genre.exists?(params[:id])
      genre = Genre.find(params[:id])
      genre.tracking_code = params[:genre][:tracking_code]
      if genre.save
      else
        raise 'hoge'
      end
    end
    redirect_to(:action => 'genre')
  end

  def list_file
    page = Page.find(params[:id])
    prepare_page
    @list = Dir.glob("#{FILE_PATH}/#{page.id}/*").sort
    @total_file_size = total_image_size(params[:id]) / 1024
  end

  def upload_file
    if params[:file][:content] && params[:file][:content] != ""
      if EXT_RE !~ File.extname(params[:file][:content].original_filename)
        @error = 'アップロード出来ないファイルです。アップロード出来るファイルは、「Microsoft Word、Microsoft Excel、一太郎、PDF、画像ファイル(jpg、png、gif)、音声ファイル(mp3, wav)」です。'
        list_file
        render(:action => 'list_file')
        return
      elsif /\A[a-zA-Z0-9\-\_.]+\z/ !~ params[:file][:content].original_filename
        @error = 'ファイル名は半角英数字のみにしてください'
        list_file
        render(:action => 'list_file')
        return
      elsif /\A\.(jpe?g|png|gif)\z/i =~ File.extname(params[:file][:content].original_filename)
        if params[:file][:content].size > 1024 * 50 &&
           !top_page_image?(params[:id],
                            params[:file][:content].original_filename)
          @error = 'アップロードする画像ファイルのサイズが50KByteの上限を越えています'
          list_file
          render(:action => 'list_file')
          return
        elsif !image_uploadable?(params[:id], params[:file][:content].size)
          @error = '画像ファイルの合計サイズが3MByteの上限を越えますのでファイルを削除してからアップロードしてください'
          list_file
          render(:action => 'list_file')
          return
        end
      end
      page = Page.find(params[:id])
      dir = attach_dir(page)
      params[:file][:content].binmode
      file_name = ERB::Util.url_encode(File.basename(params[:file][:content].original_filename))
      tmp_file = Tempfile.new('cms_upload')
      tmp_file.write(params[:file][:content].read)
      tmp_file.close
      anti_virus = CMSConfig[:anti_virus].to_a
      if anti_virus.empty? || system(*(anti_virus + [tmp_file.path]))
        FileUtils.chmod(0666, tmp_file.path)
        FileUtils.mv(tmp_file.path, "#{dir}/#{file_name}")
        redirect_to(:action => 'list_file', :id => page)
      else
        @error = 'ファイルのアップロードに失敗しました。'
        tmp_file.close!
        list_file
        render(:action => 'list_file')
        return
      end
    else
      @error = 'ファイルを選択してください'
      list_file
      render(:action => 'list_file')
      return
    end
  end

  def destroy_file
    page_id = params[:id].to_i
    page = Page.find(page_id)
    filename = File.basename(params[:filename])
    path = "#{FILE_PATH}/#{page_id}/#{filename}"
    if filename && File.exist?(path)
      File.unlink(path)
      if File.extname(filename) =~ /pdf\z/i     # for create-rast-index
        if page.current
          Job.create(:action => 'remove_attachment',
                     :arg1 => "#{page.path_base}.data/#{filename}",
                     :datetime => Time.now + 60*60*24*3650)
          # datetime is adjusted when the page is exported.
        end
      end
    end
    redirect_to(:action => 'list_file', :id => page_id)
  end

  def import
    @action = :edit
    @mode = :page
    prepare_page
    content = PageContent.new
    begin
      @uri = URI.parse(params[:uri])
      raise 'invalid uri' unless %r|\Ahttps?\z|i =~ @uri.scheme
      content.content = NKF.nkf('-w', open(@uri).read)
      content.normalize_html
      content.remove_tags_for_import
      dir = "#{FILE_PATH}/#{@page.id}"
      unless File.exist?(dir)
        Dir.mkdir(dir)
      end
      content.content = content.content.gsub(/(<img[^>]+src="|<a[^>]+href=")([^"]+)/) do |link|
        begin
          tag = $1
          link_uri = @uri + $2
          raise 'invalid uri' unless %r|\Ahttps?\z|i =~ link_uri.scheme
          file_name = File.basename(link_uri.path)
          ext_name = File.extname(file_name)
          raise if /\A[a-zA-Z0-9\-\_.]+\z/ !~ file_name
          raise if EXT_RE !~ ext_name
          File.open("#{dir}/#{file_name}", 'wb') do |f|
            f.print(open(link_uri).read)
          end
          %Q|#{tag}#{@page.genre.path}#{@page.name}.data/#{file_name}|
        rescue
          link
        end
      end
    rescue
      logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
      flash[:import_notice] = '変換に失敗しました。'
    end
    @content = @page.private
    @content.content += content.content if content.content
    render(:action => 'edit_page')
  end

  def link_check
    file = "#{RAILS_ROOT}/app/views/admin/_link_check.rhtml"
    @time = File.mtime(file) rescue nil
    @content = File.read(file) rescue nil
    render(:action => 'link_check')
  end

  def page_link_check
    @outsides = LostLink.get_lost_links(LostLink::OUTSIDE_TYPE,
                                        @user.section.id)
    @insides = LostLink.get_lost_links(LostLink::INSIDE_TYPE,
                                       @user.section.id)
  end

  def remove_lost_link
    if params[:id] && LostLink.exists?(params[:id])
      LostLink.find(params[:id].to_i).destroy
    end
    redirect_to(:action => 'page_link_check')
  end

  # configuration
  def edit_section_info
    @action = :config
    @mode = :config
    @section = Section.find(@user.section_id)
  end

  def update_section_info
    @section = Section.find(@user.section_id)
    @section.info = params[:section][:info]
    @section.save
    Job.create(:action => 'create_all_section_page', :arg1 => @section.id)
    flash[:update_section_info] = '連絡先を変更しました。'
    redirect_to(:action => 'edit_section_info')
  end

  def create_alias
    genre = Genre.find(params[:id])
    root = Genre.find(genre.parent_id)
    new_genre = root.children.create(:parent_id => genre.parent_id,
                                     :name => genre.name,
                                     :title => params[:alias][:title],
                                     :path => genre.path,
                                     :original_id => genre.id)
    if new_genre.errors.empty?
      redirect_to(:action => 'move')
    else
      move
      render(:action => 'move')
    end
  end

  def destroy_alias
    genre = Genre.find(params[:id])
    genre.destroy
    redirect_to(:action => 'move')
  end

  # manage section
  def list_section
    @action = :config
    @mode = :config
    @display_navigation = true
    @section_pages, @sections = paginate(:sections,
                                         :per_page => 10,
                                         :conditions => ['code != ?', 0],
                                         :order => 'division_id, number')
    @divisions = Division.find(:all,
                               :order => 'number').collect{|i| [i.name, i.id]}
  end

  def sort_division_section
    @action = :sort_division_section
    @mode = :config
    @divisions = Division.find(:all,
                               :conditions => ['enable = true'],
                               :order => 'number')
  end

  def update_sort_division_section
    @sections = []
    Division.transaction do
      params[:list].each_with_index do |section_id, i|
        @sections << Division.update(section_id.to_i, :number => i)
      end
    end
    render(:partial => 'sort_division_section')
  end

  def sort_section
    @action = :sort_section
    @mode = :config
    @sections = Section.find(:all,
                             :conditions => ['division_id = ?', params[:id]],
                             :order => 'number')
    @division = Division.find(params[:id]).name
  end

  def update_sort_section
    @sections = []
    Section.transaction do
      params[:list].each_with_index do |section_id, i|
        @sections << Section.update(section_id.to_i, :number => i)
      end
    end
    render(:partial => 'sort_section')
  end

  def section_search
    @display_navigation = false
    @sections = Section.find(:all,
                             :conditions => ['division_id = ?',
                                             params[:section][:division_id]],
                             :order => 'number')
    render(:partial => 'section_search')
  end

  def new_section
    @section = Section.new
    @divisions = Division.find(:all,
                               :order => 'number').collect{|i| [i.name, i.id]}
    top_genre = Genre.find(:first, :conditions => ['path = ?', '/'])
    @genres = [['指定無し', 0]]
    genre = top_genre.children.collect{|i| [i.title, i.id]}
    @genres.concat(genre)
  end

  def create_section
    @action = :config
    @mode = :config
    Section.transaction do
      @section = Section.new(params[:section])
      @section.top_genre_id = nil
      @genre = Genre.new
      sec = Section.find(:first,
                         :conditions => ['division_id = ?',
                                         @section.division_id],
                         :order => 'number desc')
      if @section.save
        section_id = @section.id
        unless params[:genre][:name].blank?
          @new_genre = Genre.find(1).children.new(:name => params[:genre][:name], :title => params[:section][:name])
          @new_genre.section_id = @section.id
          genre_id = @new_genre.id
          if @new_genre.save
            @section.top_genre_id = genre_id
            @section.save
          else
            section = @section
            @section.destroy
            new_section
            @section = section
            @section.errors.add(:name, "フォルダ名が正しくありません。半角英数字で入力してください")
            render(:action => 'new_section')
            return
          end
        else
          if !params[:genre][:id].to_i.zero?
            @section.top_genre_id = params[:genre][:id].to_i
            @section.save
          end
        end
        max = sec ? sec.number.to_i : 0
        @section = Section.find(section_id)
        @section.number = max + 1 if max
        @section.save
        flash[:section_notice] = '所属を作成しました'
        redirect_to(:action => 'list_section')
      else
        section = @section
        new_section
        @section = section
        render(:action => 'new_section')
      end
    end
  end

  def edit_section
    @action = :config
    @mode = :config
    Section.transaction do
      @section = Section.find(params[:id])
      @divisions = Division.find(:all,
                                 :order => 'number').collect{|i| [i.name, i.id]}
      top_genre = Genre.find(:first, :conditions => ['path = ?', '/'])
      @genres = [['指定無し', 0]]
      genre = top_genre.children.collect{|i| [i.title, i.id]}
      @genres.concat(genre)
      @selected_division = @section.division_id
      @selected_genre = @section.top_genre_id
    end
  end

  def update_section
    @action = :config
    @mode = :config
    param = params[:genre][:id].to_i
    Section.transaction do
      @section = Section.find(params[:id])
      if @section.update_attributes(params[:section])
        @section.top_genre_id = param.zero? ? nil : param
        @section.save
        flash[:section_notice] = '所属を編集しました'
        redirect_to(:action => 'list_section')
      else
        section = @section
        edit_section
        @section = section
        render(:action => 'edit_section')
      end
    end
  end

  def destroy_section
    Section.transaction do
      section = Section.find(params[:id])
      name = section.name
      section.destroy
      reassign_genre(params[:id])
      flash[:section_notice] = "所属(#{name})を削除しました"
      redirect_to(:action => 'list_section')
    end
  end

  # manage division
  def list_division
    @divisions = Division.find(:all, :order => 'number')
  end

  def new_division
    @division = Division.new
  end

  def create_division
    count = Division.find(:all, :order => 'number').last.number
    max = count.to_i + 1
    Division.transaction do
      @division = Division.new(:name => params[:division][:name],
                               :number => max, :enable => true)
      if @division.save
        redirect_to(:action => 'list_division')
      else
        render(:action => 'new_division')
      end
    end
  end

  def edit_division
    @division = Division.find(params[:id])
  end

  def update_division
    Division.transaction do
      @division = Division.find(params[:id])
      @division.name = params[:division][:name]
      @division.enable = false
      @division.enable = true if params[:division][:enable] == 'on'
      if @division.save
        redirect_to(:action => 'list_division')
      else
        render(:action => 'edit_division')
      end
    end
  end

  def destroy_division
    Division.transaction do
      division = Division.find(params[:id])
      division.destroy
    end
    redirect_to(:action => 'list_division')
  end

  # manage info
  def list_info
    @action = :config
    @mode = :config
    @info_pages, @infos = paginate(:infos, :per_page => 10,
                                   :order => 'last_modified desc')
  end

  def show_info
    @info = Info.find(params[:id])
  end

  def new_info
    @action = :config
    @mode = :config
    @info = Info.new
  end

  def create_info
    @action = :config
    @mode = :config
    @info = Info.new(params[:info])
    if @info.save
      flash[:notice] = 'お知らせを追加しました'
      redirect_to(:action => 'list_info')
    else
      render(:action => 'new_info')
    end
  end

  def edit_info
    @action = :config
    @mode = :config
    @info = Info.find(params[:id])
  end

  def update_info
    @action = :config
    @mode = :config
    @info = Info.find(params[:id])
    if @info.update_attributes(params[:info])
      flash[:notice] = 'お知らせを変更しました'
      redirect_to(:action => 'show_info', :id => @info)
    else
      render(:action => 'edit_info')
    end
  end

  def destroy_info
    Info.find(params[:id]).destroy
    redirect_to(:action => 'list_info')
  end

  def set_emergency_info
    @emergency_info = EmergencyInfo.find(:first, :order => 'id desc')
  end

  def update_emergency_info
    param = params[:emergency_info]
    e_info = EmergencyInfo.new
    s_time = Time.local(param['display_start_datetime(1i)'].to_i,
                        param['display_start_datetime(2i)'].to_i,
                        param['display_start_datetime(3i)'].to_i,
                        param['display_start_datetime(4i)'].to_i,
                        param['display_start_datetime(5i)'].to_i)
    e_time = Time.local(param['display_end_datetime(1i)'].to_i,
                        param['display_end_datetime(2i)'].to_i,
                        param['display_end_datetime(3i)'].to_i,
                        param['display_end_datetime(4i)'].to_i,
                        param['display_end_datetime(5i)'].to_i)
    e_info.content = param[:content]
    e_info.display_start_datetime = s_time
    e_info.display_end_datetime = e_time
    if e_info.save
      redirect_to(:action => 'config')
    else
      render(:action => 'set_emergency_info')
    end
  end

  # partial methods

  def show_info_content
    @info = Info.find(params[:id])
    render(:partial => 'info_content')
  end

  def page_list
    @name = 'tinyMCELinkList'
    @links = []
    @user.genres.find(:all, :include => 'pages').each do |genre|
      genre.pages.each do |page|
        @links << [page.title, page.path]
      end
    end
    render(:partial => 'link_list')
  end

  def genre_page_list
    @name = 'tinyMCELinkList'
    genres = @user.genres.find(:all, :include => 'pages', :conditions => ['parent_id is null and path = ?', '/'], :order => 'parent_id, no, genres.id')
    genres.concat(@user.genres.find(:all, :include => 'pages', :conditions => ['parent_id is not null'], :order => 'parent_id, no, genres.id'))
    @links = genres.collect {|genre|
      if genre.pages.empty?
        nil
      else
        [genre.title, genre.path, genre.pages.collect{|page| [page.title, "#{genre.path}#{page.name == 'index' ? '' : page.name + '.html'}"]}]
      end
    }.compact
    render(:partial => 'genre_page_list')
  end

  def image_list
    page = Page.find(params[:id])
    files = Dir.glob("#{FILE_PATH}/#{page.id}/*").sort
    @name = 'tinyMCEImageList'
    # FIXME
    @links = files.grep(/\.(gif|png|jpe?g)\z/i).collect{|i|
      file_name = File.basename(i)
      [file_name, "#{page.genre.path}#{page.name}.data/#{file_name}"]
    }
    render(:partial => 'link_list')
  end

  def file_list
    page = Page.find(params[:id])
    files = Dir.glob("#{FILE_PATH}/#{page.id}/*").sort
    @name = 'tinyMCEFileList'
    @links = files.collect{|i|
      file_name = File.basename(i)
      [file_name, "#{page.genre.path}#{page.name}.data/#{file_name}"]
    }
    render(:partial => 'link_list')
  end

  def genre_open
    @move = params[:move]
    @root = Genre.find(params[:id])
    @genre = Genre.find(params[:genre])
    @action = params[:action_name].to_sym
    render(:partial => 'genre_open')
  end

  def genre_close
    @move = params[:move]
    @root = Genre.find(params[:id])
    @genre = Genre.find(params[:genre])
    @action = params[:action_name].to_sym
    render(:partial => 'genre_close')
  end

  def list_page_revision
    prepare_page
    @page_contents = PageContent.find(:all,
                                      :conditions => ['page_id = ? AND (admission = ? OR admission = ?)', @page.id, PageContent::PUBLISH, PageContent::CANCEL],
                                      :order => 'id desc')
    @admitting = @page.admitting_page
    @waiting = @page.waiting_page
    if @waiting || (@admitting && @user.authority == User::USER)
      @action = :cannot_edit
    end
  end

  def reflect_revision
    page_content = PageContent.find(params[:id])
    @page = page_content.page
    return unless page_status_check
    @private = @page.private
    @private.content = page_content.content
    @private.user_name = nil
    @private.tel = nil
    @private.email = nil
    @private.comment = nil
    @private.save
    redirect_to(:action => 'show_page_info', :id => @private.page_id)
  end

  def edit_passwd
    @new_user = User.new
  end

  def update_passwd
    if params[:cancel]
      redirect_to(:action => 'index', :id => @page)
      return
    end
    @new_user = @user
    if params[:new][:password].blank?
      if params[:new][:password_confirmation].blank?
        flash[:update_passwd] = 'パスワード入力されていません。'
        render(:action => 'edit_passwd')
        return
      else
        flash[:update_passwd] = 'パスワード入力されていません。'
        render(:action => 'edit_passwd')
        return
      end
    else
      if params[:new][:password_confirmation].blank?
        flash[:update_passwd] = 'パスワード入力されていません。'
        render(:action => 'edit_passwd')
        return
      end
    end
    unless User.authenticate(@new_user.login, params[:now][:passwd])
      flash[:update_passwd] = '現在のパスワードが違います。'
      render(:action => 'edit_passwd')
    else
      @new_user.password = params[:new][:password]
      @new_user.password_confirmation = params[:new][:password_confirmation]
      if @new_user.save
        redirect_to(:action => 'index')
      else
        flash[:update_passwd] = 'パスワードが間違っています。半角英数字で8文字〜12文字のパスワードを入力してください。'
        render(:action => 'edit_passwd')
      end
    end
  end

  # manage user
  def list_user
    @section = Section.find(params[:id])
    @manage_users = @section.users
  end

  def edit_user
    @manage_user = User.find(params[:id])
    @manage_user.password = nil
    set_authority_list
  end

  def update_user
    @manage_user = User.find(params[:id])
    password = @manage_user.password
    param = params[:manage_user]
    if param[:name].blank?
      set_authority_list
      render(:action => 'edit_user', :id => @manage_user.id)
      return
    end
    @manage_user.attributes = param
    if param[:password].blank? && param[:password_confirmation].blank?
      @manage_user.password = ''
      @manage_user.password_confirmation = ''
    end
    if @manage_user.save
      redirect_to(:action => 'list_user', :id => @manage_user.section.id)
      return
    else
      set_authority_list
      @manage_user.password = nil
      @manage_user.password_confirmation = nil
      render(:action => 'edit_user', :id => @manage_user.id)
    end
  end

  def new_user
    @manage_user = User.new
    set_authority_list
    @manage_user.authority = 0
  end

  def create_user
    @manage_user = User.new(params[:manage_user])
    @manage_user.section_id = params[:id]
    param = params[:manage_user]
    @manage_user.authority = param[:authority]
    @manage_user.login = param[:login]
    @manage_user.mail = param[:mail]
    if @manage_user.save
      redirect_to(:action => 'list_user', :id => @manage_user.section.id)
      return
    else
      set_authority_list
      @manage_user.password = nil
      @manage_user.password_confirmation = nil
      render(:action => 'new_user', :id => @manage_user.id,
             :section_id => @manage_user.section.id)
    end
  end

  def destroy_user
    user = User.find(params[:id])
    section_id = user.section_id
    user.destroy
    redirect_to(:action => 'list_user', :id => section_id)
  end

  def list_edit_page_revision
    @action = :edit
    @mode = :info
    if Page.exists?(params[:id])
      prepare_page
      @page = Page.find(params[:id])
    else
      redirect_to(:action => 'index')
    end
  end

  def import_all
    show_genre
    @action = :import_all
    @mode = :import_all
    @file_exist = false
    @file_exist = true if File.exists?("#{Page::ZIP_FILE_PATH}/#{@user.section_id}/error")
    path = "#{Page::ZIP_FILE_PATH}/#{@user.section.id}"
    files = Dir.glob("#{path}/*.zip")
    if !files.empty?
      @path = files.first
      @file = @path.split('/').last
      if File.exist?("#{path}/user_id")
        user_id = File.open("#{path}/user_id").readlines.first.to_i
      end
      @upload_user = '既に削除されたユーザ'
      @upload_user = User.find(user_id).name if User.exists?(user_id)
      if File.exist?("#{path}/genre_id")
        genre_id = File.open("#{path}/genre_id").readlines.first.to_i
      end
      @upload_folder = '既に削除されたフォルダ'
      @upload_folder = Genre.find(genre_id).title if Genre.exists?(genre_id)
    elsif File.exist?("#{path}/error")
      @results = File.open("#{path}/error").readlines
    end
  end

  def upload_import_zip
    if params[:file][:content] && params[:file][:content] != ""
      if EXT_ZIP !~ File.extname(params[:file][:content].original_filename)
        @error = 'アップロード出来ないファイルです。アップロード出来るファイルは、zip圧縮されたファイルです。'
        import_all
        render(:action => 'import_all')
        return
      elsif /\A[a-zA-Z0-9\-\_.]+\z/ !~ params[:file][:content].original_filename
        @error = 'ファイル名は半角英数字のみにしてください'
        import_all
        render(:action => 'import_all')
        return
      elsif params[:file][:content].size > 1024 * 30000
        @error = 'zipファイルのサイズが30MByteの上限を越えています。'
        import_all
        render(:action => 'import_all')
        return
      end

      genre = Genre.find(params[:id])
      dir = zip_attach_dir(@user.section)
      params[:file][:content].binmode
      file_name = ERB::Util.url_encode(File.basename(params[:file][:content].original_filename))
      tmp_file = Tempfile.new('cms_upload')
      tmp_file.write(params[:file][:content].read)
      tmp_file.close
      anti_virus = CMSConfig[:anti_virus].to_a
      if anti_virus.empty? || system(*(anti_virus + [tmp_file.path]))
        FileUtils.chmod(0666, tmp_file.path)
        FileUtils.mv(tmp_file.path, "#{dir}/#{file_name}")
        File.open("#{dir}/genre_id", 'w') do |file|
          file.print genre.id
        end
        File.open("#{dir}/user_id", 'w') do |file|
          file.print @user.id
        end
        begin
          log = system("unzip #{dir}/#{file_name} -d #{dir}/zips/ &>/dev/null")
        rescue
          system("rm -r #{dir}/*")
          @error = "HTMLファイルが無いため、zipファイルを削除しました。"
          redirect_to(:action => 'import_all', :id => genre)
          return
        end
        dirs = Dir.glob("#{dir}/zips/**/**")
        if dirs.select{|line| line =~ /^.*\.html$/ }.empty?
          system("rm -r #{dir}/*")
          @error = "zipファイルの中にHTMLファイルが無いため、zipファイルを削除しました。"
          import_all
          render(:action => 'import_all')
          return
        end
        @error = "zipファイルをアップロードしました。"
        if File.exist?("#{dir}/error")
          system("rm #{dir}/error")
        end
        redirect_to(:action => 'import_all', :id => genre)
      else
        @error = 'ウィルスが検出されたので削除しました'
        tmp_file.close!
        import_all
        render(:action => 'import_all')
        return
      end
    else
      @error = 'ファイルを選択してください'
      import_all
      render(:action => 'import_all')
      return
    end
  end

  def destroy_zip_files
    raise 'Error' if params[:id].to_i.zero?
    path = "#{Page::ZIP_FILE_PATH}/#{params[:id]}"
    dir = Dir.glob("#{path}/*.zip")
    if !params[:id].blank? && !dir.empty?
      File.unlink(dir.first)
      File.unlink("#{path}/genre_id")
      system("rm -r #{path}/zips")
      system("rm -r #{path}/user_id")
      system("rm -r #{path}/error") if File.exists?("#{path}/error")
    end
    @error = 'zipファイルを削除しました。'
    redirect_to(:action => 'import_all')
  end

  def destroy_import_result
    begin
      system("rm #{Page::ZIP_FILE_PATH}/#{@user.section_id}/error")
    rescue

    end
    redirect_to(:action => 'import_all')
  end

  private

  def lock_page(page)
    page.lock = PageLock.new(:user_id => @user.id,
                             :session_id => session.session_id,
                             :time => Time.now)
    page.save
  end

  def unlock_page(page)
    page.lock = nil
  end

  def page_locked_by_others?(page)
    if page.lock
      if page.lock.expired?
        return false
      else
        return page.lock.session_id != session.session_id
      end
    else
      return false
    end
  end

  def attach_dir(page)
    dir = "#{FILE_PATH}/#{page.id}"
    unless File.exist?(dir)
      Dir.mkdir(dir)
    end
    dir
  end

  def zip_attach_dir(section)
    dir = "#{Page::ZIP_FILE_PATH}/#{section.id}"
    unless File.exist?(dir)
      Dir.mkdir(dir)
    end
    dir
  end

  def set_authority_list
    @authority_list = [[0, 'ホームページ担当者'],
                       [1, '情報提供責任者'],
                       [2, '運用管理者']]
  end

  def prepare_page
    prepare
    @page = Page.find(params[:id])
    @genre = @page.genre
    page_permission_check
  end

  def prepare_genre
    prepare
    @genre = params[:id] ? Genre.find(params[:id]) : @root_dir_list.first
    genre_permission_check
  end

  def failure_edit_page
    @template_list = Genre.find(:first, :conditions => ['path = ?', '/template/']).pages.collect{|i| [i.title, i.id]}
    if params[:status]
      render(:action => 'edit_page', :status => 'new')
    else
      render(:action => 'edit_page')
    end
  end

  def prepare
    # folder tree
    if admin?
      @root_dir_list = Genre.find(:all, :conditions => ['parent_id IS NULL'], :order => 'id, path desc')
    else
      section_id_list = []
      @root_dir_list = @user.genres.reject{|i|
        section_id_list[i.parent_id] ||= i.parent.section_id
        section_id_list[i.parent_id] == @user.section_id
      }
      if section_top_genre = @user.section.genre
        @root_dir_list -= [section_top_genre]
        @root_dir_list.push(section_top_genre)
      end
    end
    @status = 1
  end

  def genre_edit_page_exists?(genre)
    genre.all_pages.each do |page|
      if page_under_edit?(page)
        return true
      end
    end
    false
  end

  def page_under_edit?(page)
    (page.private_exist? || page.waiting_page) && page.current
  end

  def page_permission_check(page = @page)
    genre_permission_check(page.genre)
  end

  def genre_permission_check(genre = @genre)
    unless admin?
      raise NoPermissionError unless genre.section_id == @user.section_id
    end
  end

  def move_genre(old_path, new_path)
    # 移動されるフォルダ内のページにリンクを張っているページのリンクを
    # 書き換えて再公開する。 移動させるフォルダ内のページも再公開される。
    genre = Genre.find_by_path(new_path)
    genre_pages = genre.all_pages if genre

    # update links.
    page_links = PageLink.find(:all, :conditions => ['link LIKE ?', "#{old_path}%"])
    page_links.each do |link|
      link.replace_link_regexp(%r|^#{Regexp.quote(old_path)}|, new_path)
    end

    # update links in page_contents.
    page_content_ids = page_links.map{|pl| pl.page_content_id}.uniq.sort
    page_contents = PageContent.find(page_content_ids)
    PageContent.skip_callback(:before_save) do
      page_ids = page_contents.each do |content|
        content.replace_links_regexp(%r|^#{Regexp.quote(old_path)}|, new_path)
        content.save!
      end
    end

    # add page jobs.
    page_ids = page_contents.map {|content| content.page_id}.uniq.sort
    (genre_pages | Page.find(page_ids)).compact.each do |page|
      if page.current
        Job.create(:action => 'create_page', :arg1 => page.id,
                   :datetime => Time.now)
      end
    end
  end

  def move_page(old_path, new_path)
    new_page = Page.find_by_path(new_path)
    from_path = old_path.sub(%r!/\z!, '/index.html').sub(/\.html\z/, '')
    to_path = new_path.sub(%r!/\z!, '/index.html').sub(/\.html\z/, '')
    pages = []
    PageContent.find(:all,
                     :include => [:links],
                     :conditions => ['page_links.link LIKE ?', "#{from_path}%"]
                     ).each do |content|
      content.replace_links_regexp(%r|^#{from_path}|, to_path)
      content.save
      pages << content.page
    end
    ([new_page] | pages).compact.each do |page|
      if page.current
        Job.create(:action => 'create_page', :arg1 => page.id,
                   :datetime => Time.now)
      end
    end
  end

  def total_image_size(page_id)
    dir = "#{FILE_PATH}/#{page_id}"
    total_size = Dir["#{dir}/*"].grep(/(gif|png|jpe?g)\z/i).inject(0) do |sum, file|
      sum += File.size(file)
    end
  end

  def image_uploadable?(page_id, upload_file_size)
    total_size = total_image_size(page_id)
    return total_size + upload_file_size <= (1024 * 1024) * 3
  end

  def top_page_image?(page_id, file_name)
    (Page.find(page_id).path == "/") && (CMSConfig[:top_page_image] == file_name)
  end

  def check_mail_address(mail)
    return false unless mail =~ /@\w+[.]\w+/
    return true
  end

  def send_mail(private, status, top = nil)
#    return if private.email.blank?
    subject = nil
    from_mail = User::SUPER_USER_MAIL
    to_mail = nil
    section_manager = @user.section.users.select{|i| i.authority == 1}
    if top.nil?
      case status.to_i
      when PageContent::PUBLISH_REQUEST
        subject = '依頼'
        to_mail = section_manager.collect{|i| i.mail}
      when PageContent::PUBLISH_REJECT
        subject = '却下'
        to_mail = private.email + NotifyMailer::DOMAIN unless private.email.blank?
      when PageContent::PUBLISH
        subject = '承認'
        to_mail = private.email + NotifyMailer::DOMAIN unless private.email.blank?
      end
      if subject
        email = NotifyMailer.create_status_mail(@user.section,
                                                private.id,
                                                from_mail,
                                                to_mail,
                                                subject)
        begin
          NotifyMailer.deliver(email) unless to_mail.blank?
        rescue Net::SMTPError
          logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
        end
        if status.to_i == PageContent::PUBLISH && private.top_news == PageContent::NEWS_REQUEST
          from_mail = User::SUPER_USER_MAIL
          to_mail = User.find(:all, :conditions => ['authority = ?',
                                                    User::SUPER_USER]).collect{|i| i.mail}
          email = NotifyMailer.create_top_news_status_mail(@user.section,
                                                           private.id,
                                                           from_mail,
                                                           to_mail,
                                                           '依頼')
          begin
            NotifyMailer.deliver(email)
          rescue Net::SMTPError
            logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
          end
        end
      end
    else # top
      section = private.page.genre.section
      from_mail = User::SUPER_USER_MAIL
      to_mail = section.users.select{|i| i.authority == User::SECTION_MANAGER}.collect{|i| i.mail}
      unless private.email.blank?
        to_mail << private.email + NotifyMailer::DOMAIN
      end
      return if to_mail.empty?
      if status.to_i == PageContent::NEWS_REJECT
        email = NotifyMailer.create_top_news_status_mail(section,
                                                         private.id,
                                                         from_mail,
                                                         to_mail,
                                                         '却下')
        begin
          NotifyMailer.deliver(email)
        rescue Net::SMTPError
          logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
        end
      elsif status.to_i == PageContent::NEWS_YES
        email = NotifyMailer.create_top_news_status_mail(section,
                                                         private.id,
                                                         from_mail,
                                                         to_mail,
                                                         '承認')
        begin
          NotifyMailer.deliver(email)
        rescue Net::SMTPError
          logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
        end
      end
    end
  end

  def rubi_filter
    super if @preview
  end

  def store_enquete_items(content)
    enquete_items = content.enquete_items
    current_enquete_items = content.page.enquete_items
    current_enquete_items.each do |item|
      item.no = nil
      item.enquete_item_values.clear
    end
    enquete_items.each_with_index do |enq, index|
      if item = current_enquete_items.detect{|i| i.name == enq[:name]}
        item.no = index
      else
        item = EnqueteItem.new(:form_type => enq[:type],
                               :name => enq[:name],
                               :no => index)
        current_enquete_items << item
      end
      if enq[:values]
        enq[:values].each_with_index do |v, i|
          if (i == (enq[:values].length - 1)) && item.form_type =~ /_other/
            # Make the last item in the radio or checkbox group 'other'.
            item.enquete_item_values.create(:value => v, :other => true)
          else
            item.enquete_item_values.create(:value => v)
          end
        end
      end
    end
    current_enquete_items.each{|item| item.save}
  end

  def update_remove_attachment(content)
    page = content.page
    if Job.find(:first, :conditions => ['action = ? AND arg1 like ?',
                                          'remove_attachment',
                                          page.path_base + '.data/%'])
      unless job = Job.find_by_action_and_arg1('enable_remove_attachment',
                                               page.path_base + '.data/')
        Job.create(:action => 'enable_remove_attachment',
                   :arg1 => page.path_base + '.data/',
                   :datetime => content.begin_date || Time.now)
      else
        job.update_attribute(:datetime, content.begin_date || Time.now)
      end
    end
  end

  def layout(page_name)
    case page_name
    when 'index'
      if @genre.path == '/'
        return :top_layout
      elsif Section.find(:first, :conditions => ['top_genre_id = ?', @genre.id])
        return :section_top_layout
      else
        return :genre_top_layout
      end
    else
      return :normal_layout
    end
  end

  def page_status_check
    if page_locked_by_others?(@page)
      flash[:error] = 'あなた以外の方が編集中のため、編集出来ません'
      redirect_to(:action => 'show_page_info', :id => @page)
      return false
    elsif @user.authority == User::USER && @page.admitting_page
      flash[:error] = '公開審査中のため、編集中ページの変更はできません。'
      redirect_to(:action => 'show_page_info', :id => @page)
      return false
    elsif @page.waiting_page
      flash[:error] = '公開待ちのため、編集中ページの変更はできません。'
      redirect_to(:action => 'show_page_info', :id => @page)
      return false
    end
    return true
  end

  def reassign_genre(section_id)
    Genre.find_all_by_section_id(section_id).each do |genre|
      genre.update_attribute(:section_id, Section::SUPER_SECTION)
    end
  end
end

class NoPermissionError < StandardError; end
