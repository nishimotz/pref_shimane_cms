require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  USER = 0
  SECTION_MANAGER = 1
  SUPER_USER = 2

  AUTHORITY = {
    USER => 'ホームページ担当者',
    SECTION_MANAGER => '情報提供責任者',
    SUPER_USER => '運用管理者'}

  SUPER_USER_MAIL = CMSConfig[:super_user_mail]

  set_field_names(:name => 'ユーザ名',
                  :login => 'ユーザID',
                  :password => 'パスワード',
                  :password_confirmation => '確認用パスワード',
                  :mail => 'メールアドレス')

  belongs_to(:section)

  def authority_str
    AUTHORITY[self.authority]
  end

  def validate
    unless mail.blank?
      unless mail =~ /@#{CMSConfig[:mail_domain]}/
          errors.add(:mail, "が不正です。#{CMSConfig[:mail_domain]}のメールアドレスのみ登録出来ます。")
      end
    end
    unless /^[a-zA-Z0-9\_\-]+$/.match(login)
      errors.add(:login, 'が不正です。半角英数字のみで入力してください。')
    end
    unless password.blank?
      unless /^[a-zA-Z0-9\-]+$/.match(password)
        errors.add(:password, 'が不正です。半角英数字のみで入力してください。')
      end
    end
    unless password_confirmation.blank?
      unless /^[a-zA-Z0-9\-]+$/.match(password_confirmation)
        errors.add(:password_confirmation,
                   'が不正です。半角英数字のみで入力してください。')
      end
    end
  end

  def genres
    self.section.genres
  end

  # Please change the salt to something else, 
  # Every application should use a different one 
  @@salt = 'mjdsa02kdsal2dk00dsm'
  cattr_accessor :salt

  # Authenticate a user. 
  #
  # Example:
  #   @user = User.authenticate('bob', 'bobpass')
  #
  def self.authenticate(login, pass)
    if CMSConfig[:no_password]
      find_first(["login = ?", login])
    else
      find_first(["login = ? AND password = ?", login, sha1(pass)])
    end
  end

  protected

  # Apply SHA1 encryption to the supplied password. 
  # We will additionally surround the password with a salt 
  # for additional security. 
  def self.sha1(pass)
    Digest::SHA1.hexdigest("#{salt}--#{pass}--")
  end

  before_create :crypt_password

  # Before saving the record to database we will crypt the password 
  # using SHA1. 
  # We never store the actual password in the DB.
  def crypt_password
    write_attribute "password", self.class.sha1(password)
  end

  before_save :crypt_unless_empty

  # If the record is updated we will check if the password is empty.
  # If its empty we assume that the user didn't want to change his
  # password and just reset it to the old value.
  def crypt_unless_empty
    unless self.new_record?
      if password.empty?
        user = self.class.find(self.id)
        self.password = user.password
      else
        write_attribute "password", self.class.sha1(password)
      end
    end
  end  

  validates_uniqueness_of :login

  validates_confirmation_of :password, :message => 'が一致しません。', :if => :password_empty
  validates_length_of :login, :within => 3..20, :message => '3〜20字までのIDにしてください。'
  validates_length_of :password, :within => 8..12, :message => '8〜12字のパスワードにしてください。', :if => :password_empty
  validates_presence_of :name, :login, :password, :password_confirmation, :message => 'が入力されていません。', :if => :password_empty

  private

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
end
