require File.dirname(__FILE__) + '/../test_helper'
require 'web_monitor_controller'

# Re-raise errors caught by the controller.
class WebMonitorController; def rescue_action(e) raise e end; end

class WebMonitorControllerTest < Test::Unit::TestCase
  self.use_transactional_fixtures = false
  fixtures :genres, :web_monitors

  def setup
    @controller = WebMonitorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    create_session
  end

  def test_index
    get :index, :id => genres(:webmonitor).id
    assert_response(:success)
    assert_equal 73, assigns(:genre).id
    assert_equal 2, assigns(:web_monitors).size
  end

  def test_new_user
    get :new_user, :id => genres(:webmonitor).id
    assert_response(:success)
    assert assigns(:web_monitor)
  end

  def test_create_user
    count_org = WebMonitor.count
    post(:save_user,
         :web_monitor => {:name => 'test',
                          :login => 'test',
                          :genre_id => genres(:webmonitor).id.to_s,
                          :password => 'testtest',
                          :password_confirmation => 'testtest'})
    assert_redirected_to :controller => 'web_monitor', :action => 'index'
    follow_redirect
    assert_equal count_org + 1, WebMonitor.count
    assert_equal 73, assigns(:genre).id
    assert_equal 3, assigns(:web_monitors).size
  end

  def test_update_user
    count_org = WebMonitor.count
    post(:save_user,
         :id => web_monitors(:first).id,
         :web_monitor => {:name => 'test',
                          :login => 'test',
                          :genre_id => genres(:webmonitor).id.to_s,
                          :password => 'testtest',
                          :password_confirmation => 'testtest'})
    assert_redirected_to :controller => 'web_monitor', :action => 'index'
    follow_redirect
    assert_equal count_org, WebMonitor.count
    assert_equal 73, assigns(:genre).id
    monitor = WebMonitor.find(web_monitors(:first).id)
    assert_equal 'test', monitor.name
    assert_equal WebMonitor::EDITED, monitor.state
  end

  def test_destroy_user
    count_org = WebMonitor.count
    monitor = web_monitors(:first)
    get(:destroy_user, :id => monitor.id, :genre_id => monitor.genre_id)
    assert_redirected_to :controller => 'web_monitor', :action => 'index'
    follow_redirect
    assert_equal count_org - 1, WebMonitor.count
    assert_equal 73, assigns(:genre).id
    assert_equal 1, assigns(:web_monitors).size
  end

  def test_create_from_csv
    genre = genres(:webmonitor)
    count_org = genre.web_monitors.count
    post(:create_from_csv,
         :id => genre.id,
         :csv => uploaded_file(File.dirname(__FILE__) + '/../data/web_monitors.csv', 'text/csv'))

    genre.reload
    assert_redirected_to :controller => 'web_monitor', :action => 'index'
    follow_redirect
    assert_equal 73, assigns(:genre).id
    # @web_monitors is incremented by 3.
    assert_equal 5, assigns(:web_monitors).size
  end

  def test_create_from_csv_invalid_monitor
    genre = genres(:webmonitor)
    count_org = genre.web_monitors.count

    post(:create_from_csv,
         :id => genre.id,
         :csv => uploaded_file(File.dirname(__FILE__) + '/../data/web_monitors_error.csv', 'text/csv'))
    genre.reload

    assert_template 'new_user'
    assert_equal 73, assigns(:genre).id
    # @web_monitors should not be incremented.
    assert_equal count_org, genre.web_monitors.count

    # Make sure that the invalid record is set.
    assert_equal 'モニタ名「不正」の情報が不正です。', flash[:csv_error]
    record = assigns(:csv_invalid_record)
    assert_equal 'は3〜20字にしてください。', record.errors.on(:login)
  end

  def test_create_from_csv_invalid_file_type
    genre = genres(:webmonitor)
    count_org = genre.web_monitors.count

    post(:create_from_csv,
         :id => genre.id,
         :csv => uploaded_file("#{RAILS_ROOT}/tmp/test.png", 'image/png'))
    genre.reload

    assert_template 'new_user'
    assert_equal 73, assigns(:genre).id

    assert_equal 'test.pngはCSVファイルではありません。', flash[:csv_error]
  end

  def test_enable_genre_auth
    Job.destroy_all
    genre = genres(:webmonitor)
    post :change_genre_auth, :id => genre.id, :auth => true
    genre.reload
    assert_redirected_to :controller => 'web_monitor', :action => 'index'
    assert_equal 'フォルダのアクセス制限を「有効」に変更しました。', flash[:monitor_notice]
    assert genre.auth
    job = Job.find(:first)
    assert_equal 'create_htaccess', job.action
    assert_equal genre.id.to_s, job.arg1
  end

  def test_disable_genre_auth
    Job.destroy_all
    genre = genres(:webmonitor)
    genre.update_attribute(:auth, true)
    post :change_genre_auth, :id => genre.id, :auth => false
    genre.reload
    assert_redirected_to :controller => 'web_monitor', :action => 'index'
    assert_equal 'フォルダのアクセス制限を「無効」に変更しました。', flash[:monitor_notice]
    assert !genre.auth
    job = Job.find(:first)
    assert_equal 'destroy_htaccess', job.action
    assert_equal genre.id.to_s, job.arg1
  end

  def test_disable_genre_auth_already_disabled
    Job.destroy_all
    genre = genres(:webmonitor)
    genre.update_attribute(:auth, false)
    post :change_genre_auth, :id => genre.id, :auth => false
    genre.reload
    assert_redirected_to :controller => 'web_monitor', :action => 'index'
    assert !genre.auth
    assert 0,  Job.count
  end

  def test_edit_user
    monitor = web_monitors(:first)
    get :edit_user, :id => monitor.id, :genre_id => genres(:webmonitor).id
    assert_template 'new_user'
    assert_equal 73, assigns(:genre).id
    assert_equal 1, assigns(:web_monitor).id
    assert_nil assigns(:web_monitor).password
  end

  def test_update_monitor_info
    Job.destroy_all
    genre = genres(:webmonitor)
    post :update_monitor_info, :id => genre.id
    job = Job.find(:first)
    assert_equal 'create_htpasswd', job.action
    assert_equal genre.id.to_s, job.arg1
    assert genre.web_monitors.all? {|m| m.state == WebMonitor::REGISTERED}
  end
end
