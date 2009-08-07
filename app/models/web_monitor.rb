require 'digest/md5'

class WebMonitor < ActiveRecord::Base
  belongs_to :genre
  attr_accessor :password_confirmation

  # Monitor states
  # EDITED:    monitor info have been edited but apache2 password file is not
  #            updated to reflect the change.
  # REGISTERED: monitor info is in apache2 password file and is up to date.
  EDITED = 0
  REGISTERED = 1

  set_field_names(:name => 'モニタ名',
                  :login => 'ユーザID',
                  :password => 'パスワード',
                  :password_confirmation => 'パスワード確認用')

  before_create :crypt_password
  before_save :crypt_unless_empty
  before_save :update_genre_id_unless_empty
  before_update :update_state
  after_destroy :update_htpasswd

  validates_presence_of :name, :login
  validates_presence_of :password, :if => :password_empty
  validates_uniqueness_of :login, :scope => :genre_id
  validates_length_of :login, :within => 3..20, :too_short => 'は3〜20字にしてください。', :too_long => 'は3〜20字にしてください。'
  validates_length_of :password, :within => 6..12, :too_long => 'は6〜12字にしてください。', :too_short => 'は6〜12字にしてください。', :if => :password_empty
  validates_confirmation_of :password, :message => 'が一致しません', :if => :password_empty

  def self.create_from_csv(csv_str, genre_id)
    transaction do
      CSV.parse(csv_str) do |row|
        name, login, password = *row
        record = new(:name => name,
                     :login => login,
                     :genre_id => genre_id,
                     :password => password,
                     :password_confirmation => password)
        record.save!
      end
    end
  end

  def validate_on_update
    errors.add_to_base("ユーザIDを更新する場合は、パスワードの変更も行なってください。") if only_login_changed?
  end

  private

  def only_login_changed?
    if password.empty?
      monitor = self.class.find(self.id)
      self.login != monitor.login
    else
      false
    end
  end

  def htpasswd(pass)
    genre = Genre.find(genre_id)
    realm = genre.name
    Digest::MD5::hexdigest([login, realm, pass].join(":"))
  end

  def crypt_password
    write_attribute "password", htpasswd(password)
  end

  def crypt_unless_empty
    unless self.new_record?
      if password.empty?
        monitor = self.class.find(self.id)
        self.password = monitor.password
      else
        crypt_password
      end
    end
  end  

  def update_genre_id_unless_empty
    if !self.new_record? && genre_id.blank?
      monitor = self.class.find(self.id)
      self.genre_id = monitor.genre_id
    end
  end  

  def password_empty
    unless self.new_record?
      if password.blank? && password_confirmation.blank?
        false
      else
        true
      end
    else
      true
    end
  end

  def update_htpasswd
    if genre && genre.auth
      Job.create(:action => 'remove_from_htpasswd', :arg1 => self.genre_id, :arg2 => self.login)
    end
  end

  def update_state
    monitor = self.class.find(self.id)
    if (monitor.password != self.password) or
      (monitor.login != self.login)
      self.state = WebMonitor::EDITED
    end
  end
end
