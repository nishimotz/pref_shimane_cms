class Genre < ActiveRecord::Base
  acts_as_tree :order => "no, original_id desc, id"
  has_many :pages, :order => 'name, pages.id', :dependent => true
  has_many :web_monitors, :order => 'login', :dependent => true
  belongs_to(:section)
  validates_uniqueness_of(:name, :scope => "parent_id",
                          :message => "フォルダ名が重複しています",
                          :if => :allow_validation)

  after_destroy :create_destroy_htpasswd_job
  after_destroy :create_delete_folder_job

  def validate
    if CMSConfig[:top_genre_id] != self.id
      unless /^[a-zA-Z0-9\-\_]+$/.match(self.name)
        errors.add(:name, "URL名が正しくありません。半角英数字で入力してください")
      end
    end
    if /(^\_[a-zA-Z0-9\-\_]+$|javascripts|stylesheets|images|contents)/ =~ self.name
      errors.add(:name, "javascripts、images、stylesheets、contents、アンダースコアで始まるURL名は使用出来ません。")
    end
    if /\A\s*\z/ =~ self.title
      errors.add(:title, "タイトルが空です。")
    end
  end

  def validate_genre_title
    conv = false
    text2 = Filter::convert_non_japanese_chars(title, conv)
    invalid_chars = text2.scan(%r!<span\s*class="invalid"\s*>(.+?)</span\s*>!).collect{|i,| i}.uniq
    unless invalid_chars.empty?
      errors.add(:title, "次の文字は機種依存文字です。" + "(" + invalid_chars.join('、') + ")")
     strings = "#{invalid_chars.join('、')}"
    end
    return strings
  end

  def all_pages
    ret = []
    ret += pages
    children.each{|i| ret += i.all_pages}
    ret
  end

  def all_genres
    ret = [self]
    children.each{|i| ret += i.all_genres}
    ret
  end

  def before_save
    update_path
    self.section_id ||= Section::SUPER_SECTION
  end

  def after_save
    self.children.each {|i| i.save} if CMSConfig[:top_genre_id] != self.id
  end

  def update_path
    self[:path] = (self.parent(true).path rescue '') + name + '/'
  end

  def self.find_by_name(dir)
    self.find(:first, :conditions => ['path = ?', dir.sub(%r!/*$!, '/')])
  end

  def each_genre
    genre = self
    genres = []
    genres << genre while genre = genre.parent
    genres.reverse!
    genres.each do |genre|
      yield genre
    end
  end

  def page_list
    Page.find(:all, :conditions => ["genre_id = ?", self.id],
              :order => ['pages.name'])
  end

  def section_except_admin
    if self.section && (self.section.top_genre_id || self.section_id != Section::SUPER_SECTION)
      self.section
    else
      nil
    end
  end

  def section_name
    self.section.name rescue ''
  end

  def section_name_except_admin
    self.section_except_admin.name rescue ''
  end

  def top_news_pages
    genre_ids = self.all_genres.collect{|i| i.id}
    unless genre_ids.empty?
      Page.find(:all,
                :include => 'contents',
                :order => 'page_contents.id desc',
                :conditions => ['(page_contents.admission = ? or page_contents.admission = ?) and genre_id IN (?)',
                  PageContent::PUBLISH,
                  PageContent::CANCEL,
                  genre_ids]).select{ |page|
        page.current && page.current.top_news == PageContent::NEWS_YES
      }.sort_by{|page| page.current.date}.reverse
    else
      []
    end
  end

  def news_page_contents
    genre_ids = self.all_genres.collect{|i| i.id}
    unless genre_ids.empty?
      page_contents = Page.find(:all, :include => 'contents',
                                :order => 'page_contents.id desc',
                                :conditions => ['(page_contents.admission = ? or page_contents.admission = ?) and genre_id IN (?)',
                                  PageContent::PUBLISH, PageContent::CANCEL, genre_ids]).collect{|page|
        current = page.current
        if current && current.section_news == PageContent::SECTION_NEWS_YES
          current
        else
          nil
        end
      }.compact
      return page_contents.sort_by{|e| e.date}.reverse
    end
    return []
  end

  def destroyable?(user)
    if user.authority != User::USER
      return true
    else
      return false
    end
  end

  def editable?(user)
    if self[:section_id] == user.section_id
      return true
    elsif user.authority == User::SUPER_USER
      return true
    else
      return false
    end
  end

  def link_path
    genre = self.original_id ? Genre.find(self.original_id) : self
    if genre.uri.blank?
      return genre.path
    else
      return genre.uri
    end
  end

  def add_genre_jobs(self_genre = true)
    ret = []
    self.each_genre{|i| ret << i}
    if self_genre
      ret << self
    end
    ret.each do |g|
      if Genre.root.id != g.id
        Job.create(:action => 'create_genre', :arg1 => g.id)
      end
    end
  end

  def analytics_code
    if Genre.exists?(self.id) && Genre.find(self.id).tracking_code && !Genre.find(self.id).tracking_code.blank?
      return Genre.find(self.id).tracking_code
    else
      if self.parent
        self.parent.analytics_code
      else
        return nil
      end
    end
  end

  def create_auth_job
    Genre.transaction do
      WebMonitor.transaction do
        action = auth ? 'create_htaccess' : 'destroy_htaccess'
        Job.create(:action => action, :arg1 => id)
        web_monitors.update_all("state = #{WebMonitor::REGISTERED}")
      end
    end
  end

  def has_current_page?
    all_pages.any?{|page| page.current}
  end

  def has_edited_monitors?
    web_monitors.any?{|m| m.state == WebMonitor::EDITED} 
  end

  private

  def allow_validation
    self.original_id ? false : true
  end

  def create_destroy_htpasswd_job
    if auth
      Job.create(:action => 'destroy_htpasswd', :arg1 => id)
    end
  end

  def create_delete_folder_job
    Job.create(:action => 'delete_folder',
               :arg1 => path, :datetime => Time.now)
    add_genre_jobs(false)
  end
end
