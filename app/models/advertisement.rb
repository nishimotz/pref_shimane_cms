class Advertisement < ActiveRecord::Base
  has_one :advertisement_list

  INSIDE_TYPE = 1
  OUTSIDE_TYPE = 2

  NOT_PUBLISHED = 1
  PUBLISHED = 2

  STATE = { PUBLISHED => '公開中', NOT_PUBLISHED => '非公開'}
  SHOW_IN_HEADER = { true => '表示する', false => '表示しない'}
  SIDE_TYPE = { INSIDE_TYPE => '県の広告', OUTSIDE_TYPE => '企業広告'}

  FILE_PATH = "#{RAILS_ROOT}/files/advertisement/#{RAILS_ENV}"
  IMAGE_DIR = "/files/advertisement/#{RAILS_ENV}"
  PUBLIC_IMAGE_DIR = "#{RAILS_ROOT}/public/images/advertisement/"
  JAVASCRIPT_FILE = "#{RAILS_ROOT}/public/javascripts/banner.js"

  validates_presence_of(:side_type, :message => '広告の種類を選択してください')
  validates_presence_of(:name, :message => '広告名を入力してください')
  validates_uniqueness_of(:name, :message => 'その広告名はすでに使われています')
  validates_presence_of(:alt, :message => '画像の説明を入力してください')

  def validate
    if self.begin_date && self.end_date
      if begin_date > end_date
        errors.add(:begin_date, '開始日時が終了日時よりも後になっています')
      end
      unless Date.valid_date?(self.begin_date.year, self.begin_date.month, self.begin_date.day)
        errors.add(:begin_date, '開始日時に存在しない日を設定しています')
      end
      unless Date.valid_date?(self.end_date.year, self.end_date.month, self.end_date.day)
        errors.add(:end_date, '終了日時に存在しない日を設定しています')
      end
    end
  end

  def Advertisement.pref_advertisement
    Advertisement.find(:all, 
                       :conditions => ['side_type = ?', INSIDE_TYPE], 
                       :order => "state DESC, pref_ad_number")
  end

  def Advertisement.corp_advertisement
    Advertisement.find(:all, 
                       :conditions => ['side_type = ?', OUTSIDE_TYPE], 
                       :order => "state DESC, corp_ad_number")
  end

  def Advertisement.pref_published_advertisement
    Advertisement.find(:all, 
                       :conditions => ['side_type = ? and state = ?',
                                       INSIDE_TYPE, PUBLISHED], 
                       :order => "pref_ad_number")
  end

  def Advertisement.corp_published_advertisement
    Advertisement.find(:all, 
                       :conditions => ['side_type = ? and state = ?',
                                       OUTSIDE_TYPE, PUBLISHED], 
                       :order => "corp_ad_number")
  end

  def Advertisement.expired_advertisement
    query = "state = ? AND end_date < ?"
    Advertisement.find(:all, :conditions => [query, PUBLISHED, Time.now])
  end

  def send_advertisement_expired_mail
    email = NotifyMailer.create_expired_advertisement_exist(self)
    NotifyMailer.deliver(email)
  end

  def delete_img
    path = "#{FILE_PATH}/#{self.image}"
    begin
      if File.exist?(path) && !File.directory?(path)
        FileUtils.rm(path)
      end
    rescue
    end
  end

  def published?
    self.state == PUBLISHED ? true : false
  end

  def expired?
    Time.now > self.end_date ? true : false
  end

  def inside?
    self.side_type == INSIDE_TYPE ? true : false
  end

  def state_to_s
    STATE[self.state]
  end

  def show_in_header_to_s
    SHOW_IN_HEADER[self.show_in_header]
  end

  def side_type_to_s
    SIDE_TYPE[self.side_type]
  end
end
