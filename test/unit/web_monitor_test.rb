require File.dirname(__FILE__) + '/../test_helper'

class WebMonitorTest < Test::Unit::TestCase
  self.use_transactional_fixtures = false

  fixtures :web_monitors, :genres

  def setup
    @genre = genres(:webmonitor)
  end

  def test_create
    WebMonitor.create(:name => 'test',
                      :login => 'test_id',
                      :genre_id => @genre.id,
                      :password => 'testtest',
                      :password_confirmation => 'testtest')
    monitor = WebMonitor.find_by_name('test')
    assert monitor
    assert Digest::MD5.hexdigest(['test','webmonitor','testtest'].join(":")),
           monitor.password
  end

  def test_name
    # test for presence.
    m1 =  WebMonitor.new(:login => 'test_id',
                         :genre_id => @genre.id,
                         :password => 'testtest',
                         :password_confirmation => 'testtest')
    m1.save
    assert_equal 'を入力して下さい', m1.errors.on(:name)
  end

  def test_login
    # test for presence.
    m1 =  WebMonitor.new(:name => "test",
                         :login => '',
                         :genre_id => @genre.id,
                         :password => 'testtest',
                         :password_confirmation => 'testtest')
    m1.save
    assert m1.errors.on(:login).include?('を入力して下さい')

    # test for length.
    m2 =  WebMonitor.new(:name => "test",
                         :login => 'ak',
                         :genre_id => @genre.id,
                         :password => 'testtest',
                         :password_confirmation => 'testtest')
    m2.save
    assert_equal 'は3〜20字にしてください。', m2.errors.on(:login) 
    m3 =  WebMonitor.new(:name => "test",
                         :login => 'kakakakakakaka23kakak',
                         :genre_id => @genre.id,
                         :password => 'testtest',
                         :password_confirmation => 'testtest')
    m3.save
    assert_equal 'は3〜20字にしてください。', m3.errors.on(:login)

    # test for uniqueness
    WebMonitor.create(:name => 'test',
                      :login => 'test_id',
                      :genre_id => 1,
                      :password => 'testtest',
                      :password_confirmation => 'testtest')
    # user belonging to different genre can have the same login.
    m4 =  WebMonitor.new(:name => 'test_other',
                         :login => 'test_id',
                         :genre_id => 2,
                         :password => 'testtest',
                         :password_confirmation => 'testtest')
    m4.save
    assert_nil m4.errors.on(:login)

    # user belonging to the same genre may not have the same login.
    m5 =  WebMonitor.new(:name => 'test_other',
                         :login => 'test_id',
                         :genre_id => 1,
                         :password => 'testtest',
                         :password_confirmation => 'testtest')
    m5.save
    assert_equal 'はすでに存在します', m5.errors.on(:login)
  end

  def test_password
    m1 =  WebMonitor.new(:name => "test",
                         :login => 'test_id',
                         :genre_id => @genre.id,
                         :password => '',
                         :password_confirmation => 'different')
    m1.save
    assert m1.errors.on(:password).include?('を入力して下さい')

    m2 =  WebMonitor.new(:name => "test",
                         :login => 'test_id',
                         :genre_id => @genre.id,
                         :password => 'testtest',
                         :password_confirmation => 'different')
    m2.save
    assert_equal 'が一致しません', m2.errors.on(:password)

    m3 =  WebMonitor.new(:name => "test",
                         :login => 'test_id',
                         :genre_id => @genre.id,
                         :password => 'testt',
                         :password_confirmation => 'different')
    m3.save
    assert m3.errors.on(:password).include?('は6〜12字にしてください。')

    m4 =  WebMonitor.new(:name => "test",
                         :login => 'test_id',
                         :genre_id => @genre.id,
                         :password => 'testtesttestt',
                         :password_confirmation => 'different')
    m4.save
    assert m4.errors.on(:password).include?('は6〜12字にしてください。')

    m5 =  WebMonitor.new(:name => "test",
                         :login => 'test_id',
                         :genre_id => @genre.id,
                         :password => 'testtest',
                         :password_confirmation => '')
    m5.save
    assert_equal 'が一致しません', m5.errors.on(:password)
  end

  def test_edit_user_unmodified
    m1 = web_monitors(:first)
    org_pass = m1.password
    m1.update_attributes(:name => m1.name,
                        :login => m1.login,
                        :password => '',
                        :password_confirmation => '')
    assert m1.errors.empty?
    #password should not changed.
    assert org_pass, m1.password
  end

  def test_edit_user_only_name
    m1 = web_monitors(:first)
    m1.state = WebMonitor::REGISTERED
    m1.update_without_callbacks
    org_name = m1.name
    m1.update_attributes(:name => m1.name + '1',
                        :login => m1.login,
                        :password => '',
                        :password_confirmation => '')
    assert m1.errors.empty?
    #state should not be updated.
    assert_equal WebMonitor::REGISTERED, m1.state
  end

  def test_edit_user_only_password
    m1 = web_monitors(:first)
    m1.state = WebMonitor::REGISTERED
    m1.update_without_callbacks
    org_name = m1.name
    m1.update_attributes(:name => m1.name,
                        :login => m1.login,
                        :password => 'editpasswd',
                        :password_confirmation => 'editpasswd')
    assert m1.errors.empty?
    #state should be updated.
    assert_equal WebMonitor::EDITED, m1.state
    #password should be changed.
    assert Digest::MD5.hexdigest(['test','webmonitor','testtest'].join(":")),
           m1.password
  end

  def test_edit_user_password
    m1 = web_monitors(:first)
    org_pass = m1.password
    m1.update_attributes(:name => m1.name,
                        :login => m1.login,
                        :password => 'editedpass',
                        :password_confirmation => '')
    assert_equal 'が一致しません', m1.errors.on(:password)

    # password once edited above, but later removed.
    m1.update_attributes(:name => m1.name,
                        :login => m1.login,
                        :password => '',
                        :password_confirmation => '')
    assert m1.errors.empty?
    #password should not changed.
    assert org_pass, m1.password
  end

  def test_edit_user_only_login_fail
    m1 = web_monitors(:first)
    m1.state = WebMonitor::REGISTERED
    m1.update_without_callbacks
    org_login = m1.login
    org_pass = m1.password
    m1.update_attributes(:name => m1.name,
                        :login => m1.login + '1',
                        :password => '',
                        :password_confirmation => '')
    assert "ユーザIDを更新する場合は、パスワードの変更も行なってください。", m1.errors[:base]
    assert_equal org_login, WebMonitor.find(m1.id).login
    #state should not be updated.
    assert_equal WebMonitor::REGISTERED, WebMonitor.find(m1.id).state
  end

  def test_create_form_csv
    genre = genres(:webmonitor)
    genre.web_monitors.destroy_all
    csv_str = File.read(File.dirname(__FILE__) + '/../data/web_monitors.csv')
    WebMonitor.create_from_csv(NKF.nkf('-w -m0', csv_str), genre.id)
    records = genre.web_monitors(:order => 'login')
    assert_equal 3, records.size
    assert_equal ['河井','喜多川','鷲見'], records.map{|r| r.name}
  end

  def test_create_form_csv_error
    genre = genres(:webmonitor)
    genre.web_monitors.destroy_all
    csv_str = File.read(File.dirname(__FILE__) + '/../data/web_monitors_error.csv')

    assert_raise(ActiveRecord::RecordInvalid) do
      WebMonitor.create_from_csv(NKF.nkf('-w -m0', csv_str), genre.id)
    end

    assert_equal 0, genre.web_monitors.count
  end

  def test_after_destroy_auth_enabled
    Job.destroy_all
    m1 = web_monitors(:first)
    m1.genre.update_attribute(:auth, true)
    genre_id = m1.genre_id

    m1.destroy
    assert_equal 1, Job.count
    job = Job.find_by_action('remove_from_htpasswd')
    assert job.arg1, genre_id
    assert job.arg2, m1.login
  end

  def test_after_destroy_auth_disabled
    Job.destroy_all
    m1 = web_monitors(:first)
    m1.genre.update_attribute(:auth, false)
    m1.destroy
    assert Job.count.zero?
  end
end
