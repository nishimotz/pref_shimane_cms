#require 'acts_as_versioned'
require 'htree'
require 'uri'

class Page < ActiveRecord::Base
  ZIP_FILE_PATH = "#{RAILS_ROOT}/zip/#{RAILS_ENV}"

  has_many(:contents, :class_name => 'PageContent', :dependent => true, :order => 'page_contents.id desc')
  has_many(:revisions, :class_name => 'PageRevision', :dependent => true, :order => 'page_revisions.id desc')
  belongs_to(:genre)
  has_one(:lock, :class_name => 'PageLock', :dependent => true)
  has_many(:enquete_items, :dependent => true,
           :order => 'enquete_items.no',
           :conditions => ['enquete_items.no is not null'])
  has_many(:enquete_answers, :dependent => true,
           :order => 'enquete_answers.answered_at')

  validates_uniqueness_of(:name, :message => 'そのページ名はすでに使われています', :scope => 'genre_id')
  validates_presence_of(:name, :message => 'ページ名を入力してください')
  validates_format_of(:name, :with => /\A[a-z0-9\-\_]*\z/i,
                      :message => 'ページ名が正しくありません')
  validates_uniqueness_of(:title, :message => 'そのタイトルはすでに使われています', :scope => 'genre_id')
  validates_presence_of(:title, :message => 'タイトルを入力してください')
  before_destroy :delete_files

  def self.find_by_path(path)
    path = path + 'index.html' if %r!/\z! =~ path
    genre_path, page_name = path.scan(%r|\A(.*/)([^/]*)\.html\z|).first
    genre = Genre.find(:first, :conditions => ['path = ?', genre_path])
    return nil unless genre
    return Page.find(:first, :conditions => ['genre_id = ? and name = ?',
                genre.id, page_name || 'index'])
  end

  def self.find_all_current
    Page.find(:all, :include => 'contents',
              :order => 'page_contents.id desc',
              :conditions => ['page_contents.admission = ? or page_contents.admission = ?',
                PageContent::PUBLISH, PageContent::CANCEL]).select{|page| page.current}
  end

  def title
    super || self.name
  end

  def news_title
    if self.public.news_title.blank?
      self.title
    else
      self.public.news_title
    end
  end

  def self.index_page(genre)
    page = Page.new(:genre_id => genre.id, :name => 'index',
                    :title => genre.title)
    page.contents << PageContent.new(:content => "<%= plugin('genre_list') %>\n<%= plugin('genre_news_list') %>\n<%= plugin('page_list') %>\n")
    page
  end

  def before_create
    self.contents << PageContent.new(:admission => 0)
  end

  def private
    content = contents.detect{|i| i.admission != PageContent::PUBLISH && i.admission != PageContent::CANCEL}
    # content = contents.find(:first, :conditions => ['admission != ? and admission != ?', PageContent::PUBLISH, PageContent::CANCEL])
    unless content
      if public
        content = public.clone
        content.last_modified = Time.now
      else
        content = PageContent.new
      end
      content.admission = PageContent::EDITING
      content.page = self
    end
    content
  end

  def public
    pcs = contents.select{|i| i.admission == PageContent::PUBLISH || i.admission == PageContent::CANCEL}
    # pcs = contents.find(:all, :conditions => ['admission = ? or admission = ?', PageContent::PUBLISH, PageContent::CANCEL])
    public_content = pcs.detect{|pc|
      pc.public_term_enable? && pc.admission != PageContent::CANCEL
    }
    public_content ||= pcs.first
    return public_content
  end

  def current
    # find a first public page except waiting one.
    pc = contents.find(:first, :conditions => ["(admission = ? or admission = ?) and (begin_date is null or begin_date <= ?)", PageContent::PUBLISH, PageContent::CANCEL, Time.now], :order => "id desc")
    if pc.nil? || pc.admission == PageContent::CANCEL || !pc.public_term_enable?
      return nil
    else
      return pc
    end
  end

  def private_exist?
    contents.detect{|i| i.admission != PageContent::PUBLISH && i.admission != PageContent::CANCEL} ? true : false
  end

  def public_exist?
    if self.contents.first.admission != PageContent::CANCEL
      if !self.contents.first.public_term_enable? && !self.public
        return false
      else
        return true
      end
    else
      self.contents.each do |pc|
        if pc.public_term_enable? && pc.admission != PageContent::CANCEL
          return true
        end
      end
    end
    false
  end

  def self.status_page_list(admission, genre_ids, authority)
    if authority == User::SUPER_USER
      page_contents = PageContent.find(:all,
                             :conditions => ['admission = ?', admission])
#      page_contents = []
#      pcs.each do |pc|
#        page_content = PageContent.find(:all, :conditions => ['page_id = ?',
#                                                              pc.page_id],
#                                        :order => 'id desc').last
#        if page_content.id <= pc.id
#          page_contents << pc
#        end
#      end
      unless page_contents.empty?
        Page.find(:all, :conditions => ['id in (?)', page_contents.collect{|i| i.page_id}])
      else
        []
      end
    else
      pages = Page.find(:all, :include => [:genre],
                        :conditions => ['genres.id IN (?)', genre_ids])
      unless pages.empty?
        page_contents = PageContent.find(:all,
                                         :conditions => ['admission = ? AND page_contents.page_id IN (?)', admission, pages.collect{|i| i.id}])
        unless page_contents.empty?
          return Page.find(:all, :conditions => ['id in (?)', page_contents.collect{|i| i.page_id}])
        end
      end
      return []
    end
  end

  def self.news_page_list(top_news, genre_ids, authority)
    pcs = PageContent.find(:all,
                           :conditions => ['top_news = ? AND admission = ? AND (end_date IS NULL OR end_date >= ?)',
                             top_news, PageContent::PUBLISH, Time.now])
    page_contents = pcs.select do |pc|
      page_content = PageContent.find(:first,
                                      :conditions => ['page_id = ? and (admission = ? or admission = ?)',
                                        pc.page_id, PageContent::PUBLISH, PageContent::CANCEL],
                                      :order => 'page_contents.id desc')
      page_content.id == pc.id
    end
    if page_contents.empty?
      return []
    else
      if authority == User::SUPER_USER
        return Page.find(:all, :conditions => ['id IN (?)', page_contents.collect{|i| i.page_id}])
      else
        return Page.find(:all, :conditions => ['id IN (?) and genre_id IN (?)', page_contents.collect{|i| i.page_id}, genre_ids])
      end
    end
  end

  def section
    self.genre.section
  end

  def path_base
    "#{genre.path}#{name}"
  end

  def path
    return '' unless genre
    if name == 'index'
      genre.path
    else
      "#{path_base}.html"
    end
  end

  def basename
    (name || '').sub(%r|.*/(.+)|, '\1')
  end

  def name
    super || ''
  end

  def _new_index_content
    self.content = "<%= plugin('genre_list') %>\n<%= plugin('page_list') %>"
  end

  def public_enable?
    if public && public.begin_date
#      begin_date = Time.local(public.begin_date.year, public.begin_date.month, public.begin_date.day, public.begin_date.hour, public.begin_date.min)
      if public.end_date
#        end_date = Time.local(public.end_date.year, public.end_date.month, public.end_date.day, public.end_date.hour, public.end_date.min)
        return true if Time.now > public.begin_date && Time.now < public.end_date
      else
        return true if Time.now > public.begin_date
      end
    else
      if public
        return true
      end
    end
    false
  end

  def wait_public_page_exist?
    pcs = contents.select{|i| i.admission == PageContent::PUBLISH || i.admission == PageContent::CANCEL}
    return false if pcs && pcs.first && pcs.first.public_term_enable?
    if pcs.size > 1
      return true
    end
    return false
  end

  def edge_public
    contents.detect{|i| i.admission == PageContent::PUBLISH || i.admission == PageContent::CANCEL}
  end

  def validate_page_name
    unless /\A[a-zA-Z0-9\-\_]+\z/.match(self.name)
      return false
    end
    return false if allow_validation
    return true
  end

  def validate_page_title
    conv = false
    text2 = Filter::convert_non_japanese_chars(title, conv)
    invalid_chars = text2.scan(%r!<span\s*class="invalid"\s*>(.+?)</span\s*>!).collect{|i,| i}.uniq
    unless invalid_chars.empty?
     strings = "#{invalid_chars.join('、')}"
    end
    return strings
  end

  def public_page
    # 公開中または公開停止のページで、公開開始日時が設定されていないか、公開期間内か、公開開始日時が過去か、公開停止か過去のページ
    pcs = contents.select{|i| i.admission == PageContent::PUBLISH || i.admission == PageContent::CANCEL}
    return pcs.detect do |pc|
      pc.begin_date.nil? ||
        (pc.begin_date && pc.end_date && pc.begin_date <= Time.now && pc.end_date >= Time.now) ||
        (pc.begin_date && pc.begin_date <= Time.now) ||
        (pc.end_date && pc.end_date <= Time.now)
    end
  end

  def private_page
    # return a private page or a waiting public page.
    content = contents.detect{|i| i.admission != PageContent::PUBLISH && i.admission != PageContent::CANCEL}
    if content
      return content
    else
      content = contents.detect{|i| i.admission == PageContent::PUBLISH}
      if content && content.begin_date && content.begin_date > Time.now
        return content
      else
        return nil
      end
    end
  end

  def admitting_page
    # return an admitting private page exists.
    content = contents.find(:first, :conditions => ['admission != ? and admission != ?', PageContent::PUBLISH, PageContent::CANCEL])
    if content && content.admission == PageContent::PUBLISH_REQUEST
      return content
    else
      return false
    end
  end

  def waiting_page
    # return an waiting public page if exists.
    content = contents.find(:first, :conditions => ['admission = ?', PageContent::PUBLISH])
    if content && content.begin_date && content.begin_date > Time.now
      return content
    else
      return false
    end
  end

  def destroyable?(user)
    if self.current || self.waiting_page
      return false
    elsif !self.edge_public && self.private_page.admission == PageContent::EDITING
      return true
    elsif user.authority != User::USER
      return true
    else
      return false
    end
  end

  def genres
    ret = []
    self.genre.each_genre{|i| ret << i}
    ret << self.genre
    ret
  end

  def add_revision(revision)
    self.revisions.last.destroy if self.revisions.count > 9
    self.revisions << revision
    self.save
  end

  def section_manager
    self.genre.section.users.detect{|i| i.authority == User::SECTION_MANAGER}
  end

  def send_enquete_update_mail
    public = self.public_page
    to_address = self.section_manager.mail
    email = NotifyMailer.create_enquete_answer_exist(self.section, public.id,
                                              '', to_address, '')
    NotifyMailer.deliver(email)
  end

  def owner_police?
    return true if CMSConfig.has_key?(:section_ids) && section.id == CMSConfig[:section_ids][:police]
    return false
  end

  def section_top_genre_path
    if self && self.section && self.section.top_genre_id && Genre.exists?(self.section.top_genre_id)
      return Genre.find(self.section.top_genre_id).path
    end
    return nil
  end

  def self.top_news(args, genre = nil)
    new_pages = []
    # filter by genre name if genre option is given.
    if genre
      new_pages = genre.top_news_pages
    else
      page_contents = PageContent.find(:all,
                                       :conditions => ['top_news = ?',
                                         PageContent::NEWS_YES])
      unless page_contents.empty?
        news = Page.find(:all,
                         :conditions => ['id IN (?)',
                           page_contents.collect{|i| i.page_id}]
                        ).select{|i| i.current}.sort_by{|i| i.current.date}.reverse
        news.each do |d|
          if d.current.top_news == PageContent::NEWS_YES
            new_pages << d
          end
        end
      end
    end

    # select page which is published after max_date days ago.
    if args[1] && !args[1].to_i.zero?
      max_date = args[1].to_i * 60 * 60 * 24
      new_pages.reject! do |e|
        (Time.now - e.current.date) > max_date
      end
    end

    return new_pages
  end

  def self.genre_news(args, genre)
    page_content_list = genre.news_page_contents
    if args[1] && !args[1].to_i.zero?
      max_date = args[1].to_i * 60 * 60 * 24
      page_content_list.reject! do |e|
        (Time.now - e.date) > max_date
      end
    end
    return page_content_list
  end

  def self.section_news(genre)
    list = []
    genre_id_list = genre.section.genres.collect{|i| i.id}
    sql = 'genre_id in (?) and page_contents.section_news = ?'
    Page.find(:all, :include => 'contents',
              :conditions => [sql, genre_id_list,
                              PageContent::SECTION_NEWS_YES]).each do |d|
      pc = d.current
      if pc && pc.section_news == PageContent::SECTION_NEWS_YES
        list << pc
      end
    end
    return [] if list.empty?
    page_lists = list.sort_by{|i| i.date}.reverse
    return page_lists
  end

  def rss_create?
    return true if self.current && PageContent::RSS_REGEXP =~ self.current.content
    return false
  end

  def gikai?
    section_id = CMSConfig[:gikai]
    return true if self.genre.section_id == section_id
    return false
  end

  def template
    section.template
  end

  private
  def delete_files
    FileUtils.rm_rf("#{AdminController::FILE_PATH}/#{id}")
  end
end
