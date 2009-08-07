require File.dirname(__FILE__) + '/../test_helper'
require 'visitor_controller'

# Re-raise errors caught by the controller.
class VisitorController; def rescue_action(e) raise e end; end

class VisitorControllerTest < Test::Unit::TestCase
  fixtures :genres, :pages, :page_contents, :sections

  def setup
    @controller = VisitorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @methods    = [:view]

    FileUtils.mkdir("#{AdminController::FILE_PATH}/1")
    FileUtils.copy_file("#{RAILS_ROOT}/tmp/test.png", "#{AdminController::FILE_PATH}/1/1.png")
  end

  def teardown
    FileUtils.rm_rf(Dir.glob("#{AdminController::FILE_PATH}/1*"))
  end

  def test_html
    get(:view, :path => ['genre1', 'genre2', 'page2.html'])
    assert_response(:success)
    assert_template('page')
    get(:view, :path => ['genre1', 'genre2'])
    assert_response(:success)
    assert_template('page')
    assert_valid_markup
  end

  def test_qr_code
    get(:view, :path => ['genre1', 'index.png'])
    assert_response(:success)
    assert_equal(@response.headers['Content-Type'], 'image/png')
    get(:view, :path => ['genre1', 'genre2', 'page2.png'])
    assert_response(:success)
    assert_equal(@response.headers['Content-Type'], 'image/png')
  end

  def test_not_found
    get :view, :path => ['culture', 'notfound.html']
    assert_response(:missing)
    assert_template('not_found')
  end

  def test_not_found_2
    get :view, :path => ['culture', 'stylesheets', 'home.css']
    assert_response(:missing)
    assert_template('not_found')
  end

  def test_not_found_3
    get :view, :path => ['images', 'notfound.png']
    assert_response(:missing)
    assert_template('not_found')
  end

  def test_attached_file
    get :view, :path => ['genre1', 'index.data', '1.png']
    assert_response(:success)
    assert_equal(@response.headers['Content-Type'], 'image/png')
  end

  def test_advertisement_img_file
    file_name = '1.png'
    file_path = Advertisement::FILE_PATH
    FileUtils.copy_file("#{RAILS_ROOT}/tmp/test.png", "#{file_path}/#{file_name}")
    get :view, :path => ['advertisement.data', file_name]
    assert_response(:success)
    assert_equal(@response.headers['Content-Type'], 'image/png')
    FileUtils.rm_f("#{file_path}/#{file_name}")
  end

  def test_news_html
    get :view, :path => ['news.1.html']
    assert_response(:success)
    assert_template('page')
  end

  def test_enquete
    get :view, :path => ['enquete', 'enquete_test.html']
    assert_response(:success)
    assert_template('page')
    assert(@response.body.include?('<input name="質問1" type="checkbox" value="A" /> A'))
    assert(@response.body.include?('<input name="質問1" type="checkbox" value="B" /> B'))
    assert(@response.body.include?('<input name="質問2" type="checkbox" value="A" /> A'))
    assert(@response.body.include?('<input name="質問2" type="checkbox" value="B" /> B'))
    assert(@response.body.include?('<input name="質問2_other" size="80" type="text" value="" />'))
    assert(@response.body.include?('<input checked="checked" name="質問3" type="radio" value="A" /> A'))
    assert(@response.body.include?('<input name="質問3" type="radio" value="B" /> B'))
    assert(@response.body.include?('<input checked="checked" name="質問4" type="radio" value="A" /> A'))
    assert(@response.body.include?('<input name="質問4" type="radio" value="B" /> B'))
    assert(@response.body.include?('<input name="質問4_other" size="80" type="text" value="" />'))
    assert(@response.body.include?('<input name="質問5*" size="80" type="text" value="" />'))
    assert(@response.body.include?('<textarea cols="80" name="質問6" rows="6" style="width: 80%;"></textarea>'))
    assert(@response.body.include?('<input name="commit" type="submit" value="確認画面へ" />'))
  end

  def test_enquete_without_submit_plugin
    get :view, :path => ['enquete', 'enquete_test2.html']
    assert_response(:success)
    assert_template('page')
    assert(@response.body.include?('<input name="commit" type="submit" value="確認画面へ" />'))
  end

  def test_analytics_code
    get(:view, :path => ['genre1', 'genre2', 'page2.html'])
    assert_tag(:tag => "script")
  end

  def test_view_set_advertisement_top_page
    get(:view, :path => [''])
    assert assigns(:pref_ads)
    assert assigns(:corp_ads)
  end

  def test_view_set_advertisement_other_page
    get(:view, :path => ['genre1', 'genre2', 'page2.html'])
    assert_nil assigns(:pref_ads)
    assert_nil assigns(:corp_ads)
  end

  def test_show_set_advertisement_top_page
    top_page = pages(:top_page)
    get(:show, :id => top_page.id)
    assert assigns(:pref_ads)
    assert assigns(:corp_ads)
  end

  def test_show_set_advertisement_other_page
    get(:show, :id => 1)
    assert_nil assigns(:pref_ads)
    assert_nil assigns(:corp_ads)
  end

  def test_show_revision_set_advertisement_top_page
    top_page_content = create_top_page_contents
    get(:show_revision, :id => top_page_content.id)
    assert assigns(:pref_ads)
    assert assigns(:corp_ads)
  end

  def test_show_revision_set_advertisement_other_page
    get(:show_revision, :id => 1)
    assert_nil assigns(:pref_ads)
    assert_nil assigns(:corp_ads)
  end
  # end test for plice specific style
  
  private
  def create_top_page_contents
    top_page = pages(:top_page)
    PageContent.create(:page_id => top_page.id)
  end
end
