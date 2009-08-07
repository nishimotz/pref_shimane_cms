require File.dirname(__FILE__) + '/../test_helper'
require 'site_controller'

# Re-raise errors caught by the controller.
class SiteController; def rescue_action(e) raise e end; end

class SiteControllerTest < Test::Unit::TestCase
  fixtures :users, :pages

  def setup
    @controller = SiteController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    create_session
    Time.redefine_now Time.local(2008, 2, 2, 22, 22)
  end

  def test_config
    get(:config)
    assert_response(:success)
    assert_equal 'test', assigns(:current_theme).name

    themes = assigns(:themes)
    assert_equal 2, themes.size
    assert_equal *[['test', 'green'],themes.map{|t| t.name}].map{|arg| Set.new arg}

    assert_equal '/top/photo/link.html', assigns(:top_photo_link)
  end

  def test_config_theme_change_exists
    Job.create(:action => 'change_theme',
               :arg1 => 'test',
               :datetime => Time.now)
    get(:config)
    assert_response(:success)
    assert_equal('テーマの変更予定があります。(変更日時: 2008年 2月 2日 22時22分, テーマ: 青)', flash[:notice_theme])

    assert_equal('test', assigns(:current_theme).name)
  end

  def test_config
    get(:config)
    assert_response(:success)
    assert_equal 'test', assigns(:current_theme).name

    themes = assigns(:themes)
    assert_equal 2, themes.size
    assert_equal *[['test', 'green'],themes.map{|t| t.name}].map{|arg| Set.new arg}

    assert_equal '/top/photo/link.html', assigns(:top_photo_link)
  end

  def test_change_theme
    job_count = Job.count
    post(:change_theme,
         :theme => 'green',
         :date => {:year => 2008,
                   :month => 2,
                   :day => 2,
                   :hour => 22,
                   :minute => 30})
    assert_redirected_to :controller => 'site', :action => 'config'
    assert_equal  'テーマを(緑)に更新しました。', flash[:notice_theme]
    assert_equal job_count + 1, Job.count
    job = Job.find_by_action 'change_theme'
    assert_equal 'green', job.arg1
    assert_equal nil, job.arg2
    assert_equal Time.local(2008, 2, 2, 22, 30), job.datetime
  end

  def test_overwrite_change_theme
    old_job = Job.create(:action => 'change_theme',
                         :arg1 => 'test',
                         :datetime => Time.now)
    job_count = Job.count

    post(:change_theme,
         :theme => 'green',
         :date => {:year => 2008,
                   :month => 2,
                   :day => 2,
                   :hour => 22,
                   :minute => 30})
    assert_redirected_to :controller => 'site', :action => 'config'
    assert_equal  'テーマを(緑)に更新しました。', flash[:notice_theme]

    # old_job should be destroyed.
    assert_equal job_count, Job.count
    assert_raise(ActiveRecord::RecordNotFound) do
      Job.find(old_job.id)
    end

    # new job should be added.
    job = Job.find_by_action 'change_theme'
    assert_equal 'green', job.arg1
    assert_equal nil, job.arg2
    assert_equal Time.local(2008, 2, 2, 22, 30), job.datetime
  end

  def test_change_theme_invalid_date
    job_count = Job.count
    post(:change_theme,
         :theme => 'green',
         :date => {:year => 2008,
                   :month => 2,
                   :day => 2,
                   :hour => 22,
                   :minute => 22 - 1})
    assert_response :success
    assert_equal  '更新日時が過去の日時です。', flash[:error]
    assert_equal job_count, Job.count
    assert_nil Job.find_by_action('change_theme')
  end

  def test_change_top_photo_link
    post(:change_top_photo_link,
         :top_photo_link => '/top/photo/link.html')
    assert_redirected_to :controller => 'site', :action => 'config'
    assert_equal  'トップページの写真のリンク先URLを(/top/photo/link.html)に更新しました。リンクの変更を反映するためには、トップページの内容を編集し公開処理を行ってください。', flash[:notice_top_photo_link]
    assert_equal SiteComponents[:top_photo_link], '/top/photo/link.html'
  end
end
