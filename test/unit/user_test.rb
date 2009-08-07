require File.dirname(__FILE__) + '/../test_helper'

# Set salt to 'change-me' because thats what the fixtures assume. 
User.salt = 'mjdsa02kdsal2dk00dsm'

class UserTest < Test::Unit::TestCase
  fixtures :users

  def setup
    @bob = User.find(1)
  end
  
  def teardown
    destory_test_user
  end

  def test_auth
#    assert(User.authenticate("kouhou2", "test"))
    assert_nil(User.authenticate("nonbob", "test"))
  end

  def test_disallowed_passwords
    u = User.new
    u.name = 'きたがわ'
    u.login = "nonbob"
    u.password = u.password_confirmation = "tiny"
    assert !u.save
    assert u.errors.invalid?('password')
    u.password = u.password_confirmation = "hugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge"
    assert !u.save     
    assert u.errors.invalid?('password')
    u.password = u.password_confirmation = ""
    assert !u.save    
    assert u.errors.invalid?('password')
    u.password = u.password_confirmation = "bobs-secure"
    u.mail = "noreply@#{CMSConfig[:mail_domain]}"
    assert u.save
    assert u.errors.empty?
  end

  def test_validates_presence
    validates_presence_of("name")
    validates_presence_of("login")
    validates_presence_of("password")
    validates_presence_of("password_confirmation")
  end

  def test_validate_length_of_password
    create_test_user
    @user.password = "short"
    @user.password_confirmation = "short"
    assert !@user.save
    assert @user.errors[:password].include?("は8文字以上で入力してください")
  end

  def test_validates_confirmation_of_password
    create_test_user
    @user.password = "password"
    @user.password_confirmation = "different"
    assert !@user.save
    assert @user.errors[:password].include?("が一致しません。")
  end

  def test_validates_uniqueness_of_login
    create_test_user
    @user.login = users(:normal_user).login
    assert !@user.save
    assert @user.errors[:login].include?("はすでに存在します")
  end

  def test_bad_logins

    u = User.new  
    u.password = u.password_confirmation = "bobs_secure"

    u.login = "x"
    assert !u.save     
    assert u.errors.invalid?('login')
    
    u.login = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhug"
    assert !u.save     
    assert u.errors.invalid?('login')

    u.login = ""
    assert !u.save
    assert u.errors.invalid?('login')

    u.login = "okbob"
    u.mail = "noreply@#{CMSConfig[:mail_domain]}"
    u.password = 'testtest'
    u.password_confirmation = 'testtest'
    u.name = 'test'
    assert u.save
    assert u.errors.empty?
      
  end


  def test_collision
    u = User.new
    u.login = "kouhou1"
    u.password = u.password_confirmation = "bobs_secure"
    assert !u.save
  end


  def test_create
    u = User.new
    u.login      = "nonexistingbob"
    u.password = u.password_confirmation = "bobs-secure"
    u.name = 'てすと'
    u.mail = "noreply@#{CMSConfig[:mail_domain]}"
    assert u.save
  end
  
  def test_sha1
    u = User.new
    u.name = 'テスト'
    u.login = "nonexistingbob"
    u.password = u.password_confirmation = "bobssecure"
    u.mail = "noreply@#{CMSConfig[:mail_domain]}"
    assert u.save
        
    assert_equal '81dd112c9dd21905d230980a94fd6a1cd02d8401', u.password
    assert(User.authenticate('nonexistingbob', 'bobssecure'))
  end

  private

  def create_test_user
    @user = User.new :name => "test",
                     :login => "test",
                     :password => "password",
                     :password_confirmation => "password",
                     :mail => "test@#{CMSConfig[:mail_domain]}"
  end

  def destory_test_user
    @user.destroy if @user
  end

  def validates_presence_of(attr)
    create_test_user
    @user.send(attr + "=", "")
    assert !@user.save
    assert @user.errors[attr].include?("が入力されていません。")
  end
end
