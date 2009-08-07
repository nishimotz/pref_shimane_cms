class Section < ActiveRecord::Base
  has_many(:users, :order => 'login', :dependent => true)
  has_many(:genres, :order => 'path')
  has_many(:mailmagazines, :order => 'mail_address')
  belongs_to(:genre, :foreign_key => 'top_genre_id')
  has_many(:boards)
  belongs_to(:division)
  validates_uniqueness_of(:ftp, 
                          :if => Proc.new{|u| !u.ftp.blank?},
                          :message => "フォルダ名が重複しています")
  validates_format_of(:ftp, 
                      :if => Proc.new{|u| !u.ftp.blank?},
                      :with => /\A\/contents\/[\/\w]*\z/,
                      :message => "/contents/からはじまる書式で入力してください")


  SUPER_SECTION = 234
  CONTENTS_PATH = /\A\/contents\//

  def self.super_section
    self.find(SUPER_SECTION)
  end

  def list    
    div = Division.find(self.division_id)
    s_list = div.sections
  end

  def info
    super || ''
  end

  def validate
    if self.name.blank?
      errors.add(:name, "所属名が入力されていません。")
    end
    if self.code.blank?
      errors.add(:name, "所属コードが入力されていません。")
    end
  end

  def self.top_genre_ary
    return self.find(:all, :select => :top_genre_id).collect{|i| i.top_genre_id}
  end

  def before_save
    self.ftp = nil if self.ftp.blank?
  end

  def template
    if CMSConfig[:gikai_section_id] == self.id
      'gikai'
    else
      'page'
    end
  end
end
