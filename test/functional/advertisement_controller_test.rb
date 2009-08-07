require File.dirname(__FILE__) + '/../test_helper'
require 'advertisement_controller'

# Re-raise errors caught by the controller.
class AdvertisementController; def rescue_action(e) raise e end; end

class AdvertisementControllerTest < Test::Unit::TestCase
  fixtures :advertisements, :users

  def setup
    @controller = AdvertisementController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    create_session

    @file_path   = Advertisement::FILE_PATH
    Advertisement.find(:all).each do |ad|
      FileUtils.copy_file("#{RAILS_ROOT}/tmp/test.png", "#{@file_path}/#{ad.image}")
    end
  end

  def teardown
    Advertisement.find(:all).each do |ad|
      FileUtils.rm_f("#{@file_path}/#{ad.image}") if ad.image
    end
  end

  def test_index
    get(:index)
    assert_response(:success)
    assert_template('list')
  end

  def test_access_denied
    users = [users(:normal_user),users(:section_manager)]
    users.each do |user|
      @request.session[:user] = user

      get(:index)
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get(:list)
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get :new, :id => advertisements(:pref1).id
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get :new, :id => advertisements(:pref1).id
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get :edit, :id => advertisements(:pref1).id
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get :change_image, :id => advertisements(:pref1).id
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get :delete, :id => advertisements(:pref1).id
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      post :create
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      post :upadate
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get :set_state
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get :sort
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      post :change_state
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      get :preview
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"

      post :update_advertisement
      assert_response(:redirect)
      assert_redirected_to :controller => "admin", :action => "index"
    end
  end

  def test_list
    get(:list)
    assert_response(:success)
    assert_template('list')
    pref_ads = assigns(:pref_ads)
    corp_ads = assigns(:corp_ads)
    assert_equal(2, pref_ads.size)
    assert_equal(2, corp_ads.size)
  end

  def test_list_order
    get(:list)
    assert_response(:success)
    assert_template('list')
    pref_ads = assigns(:pref_ads)
    corp_ads = assigns(:corp_ads)
    (0...(pref_ads.length - 1)).each do |i|
      assert pref_ads[i].state >= pref_ads[i+1].state
    end
    (0...(corp_ads.length - 1)).each do |i|
      assert corp_ads[i].state >= corp_ads[i+1].state
    end
  end

  def test_new
    get :new
    assert_response :success
    assert_template "edit"
  end

  def test_create
    post :create, :advertisement => {
                      :name => "test",
                      :advertiser => "test",
                      :image_file => uploaded_file("#{RAILS_ROOT}/tmp/test.png", "image/png"),
                      :alt => "test file",
                      :url => "http://www.example.com",
                      :begin_date => Time.local(2006,1,9),
                      :end_date => Time.local(2006,2,9), 
                      :side_type => Advertisement::INSIDE_TYPE,
                      :show_in_header => true}
    assert_redirected_to :action => 'list'
    advertisement = Advertisement.find_by_name('test')
    assert(File.exist?("#{@file_path}/#{advertisement.id}.png"))
  end

  def test_blank_image_name
    error = 'ファイルを選択してください'
    post :create, :advertisement => {:name => "blank image"}
    assert_equal error, assigns(:advertisement).errors.on(:image_file)
    assert_template 'edit'
  end

  def test_invalid_images
    tmp_dir = "#{RAILS_ROOT}/tmp"
    filename = 'test.wav'
    error = '画像ファイル(jpg、png、gif)を選択してください'
    FileUtils.copy_file("#{tmp_dir}/test.png", "#{tmp_dir}/#{filename}")
    post :create, :advertisement => {
                      :image_file => uploaded_file("#{tmp_dir}/#{filename}", "image/png")}
    assert_equal error, assigns(:advertisement).errors.on("image_file")
    assert_template 'edit'
    FileUtils.rm_f("#{tmp_dir}/#{filename}")
  end

  def test_show
    get :show, :id => advertisements(:pref1).id
    assert_response(:success)
    assert_template("show")
    assert_equal advertisements(:pref1), assigns(:advertisement)
  end

  def test_edit
    get :edit, :id => advertisements(:pref1).id
    assert_response(:success)
    assert_template("edit")
    assert_equal(advertisements(:pref1), assigns(:advertisement))
  end

  def test_delete
    advertisement = advertisements(:pref1)
    advertisement.update_attributes(:state => Advertisement::NOT_PUBLISHED)
    assert(File.exist?("#{@file_path}/#{advertisement.id}.png"))
    get :delete, :id => advertisement.id
    assert_redirected_to :action => 'list'
    assert_nil Advertisement.find_by_id(advertisement.id)
    assert(!File.exist?("#{@file_path}/#{advertisement.id}.png"))
  end

  def test_delete_failure
    message =  '公開中のページは削除できません'
    advertisement = advertisements(:pref1)
    advertisement.update_attributes(:state => Advertisement::PUBLISHED)
    assert(File.exist?("#{@file_path}/#{advertisement.id}.png"))
    get :delete, :id => advertisement.id
    assert_equal message, flash[:advertisement_notice]
    assert_redirected_to :action => 'list'
    assert Advertisement.find_by_id(advertisement.id)
    assert(File.exist?("#{@file_path}/#{advertisement.id}.png"))
  end

  def test_change_image
    advertisement = advertisements(:pref1)
    assert(File.exist?("#{@file_path}/#{advertisement.image}"))
    get :change_image, :id => advertisement.id
    assert(!File.exist?("#{@file_path}/#{advertisement.image}"))
    advertisement.reload
    assert_nil advertisement.image
    assert_response(:success)
    assert_template 'edit'
  end

  def test_update_after_image_change
    post :update, 
         :id => advertisements(:pref1).id,
         :advertisement => {
                      :name => "test",
                      :advertiser => "test",
                      :image_file => uploaded_file("#{RAILS_ROOT}/tmp/test.png", "image/png"),
                      :alt => "test file",
                      :url => "http://www.example.com",
                      :begin_date => Time.local(2006,1,9),
                      :end_date => Time.local(2006,2,9), 
                      :side_type => Advertisement::INSIDE_TYPE,
                      :show_in_header => true }
    assert_redirected_to :action => 'list'
  end

  def test_update_without_image_change
    post :update, 
         :id => advertisements(:pref1).id,
         :advertisement => {
                      :name => "test",
                      :advertiser => "test",
                      :alt => "test file",
                      :url => "http://www.example.com",
                      :begin_date => Time.local(2006,1,9),
                      :end_date => Time.local(2006,2,9), 
                      :side_type => Advertisement::INSIDE_TYPE,
                      :show_in_header => true }
    assert_redirected_to :action => 'list'
  end

  def test_update_failure
    post :update, 
         :id => advertisements(:pref1).id,
         :advertisement => {
                      :name => "pref2",
                      :advertiser => "test",
                      :image_file => uploaded_file("#{RAILS_ROOT}/tmp/test.png", "image/png"),
                      :alt => "test image",
                      :url => "http://www.example.com",
                      :begin_date => Time.local(2006,1,9),
                      :end_date => Time.local(2006,2,9), 
                      :side_type => Advertisement::INSIDE_TYPE,
                      :show_in_header => true}
    assert_equal "その広告名はすでに使われています",  assigns(:advertisement).errors.on(:name) 
    assert_template "edit"
  end

  def test_set_state
    get :set_state
    assert_response(:success)
    assert_template('set_state')
  end

  def test_change_state
    setup_advertisement_list
    post :change_state, 
         :advertisement => {
           advertisements(:pref1).id => Advertisement::PUBLISHED,
           advertisements(:pref2).id => Advertisement::NOT_PUBLISHED,
           advertisements(:corp1).id => Advertisement::PUBLISHED,
           advertisements(:corp2).id => Advertisement::NOT_PUBLISHED }
    assert_redirected_to :action => "sort"
    pref_ads = AdvertisementList.pref_published_advertisements
    corp_ads = AdvertisementList.corp_published_advertisements
    assert_equal 1, pref_ads.size
    assert_equal 1, corp_ads.size
  end

  def test_change_state_cancel
    message = '設定変更を破棄しました。'
    setup_advertisement_list
    post :change_state, :cancel => 'キャンセル'
    assert_redirected_to :action => "list"
    assert 0, AdvertisementList.count
  end

  def test_sort
    setup_advertisement_list
    AdvertisementList.update_all("state = #{Advertisement::PUBLISHED}")
    get :sort
    assert_response(:success)
    assert_template('sort')
    pref_ads = assigns(:pref_ads)
    corp_ads = assigns(:corp_ads)
    assert_equal 2, pref_ads.size
    assert_equal 2, corp_ads.size
    pref_ads.each_with_index do |ad, i|
      assert_equal(ad.pref_ad_number, i)
    end
    corp_ads.each_with_index do |ad, i|
      assert_equal(ad.corp_ad_number, i)
    end
  end

  def test_update_sort_corp_advertisement
    setup_advertisement_list
    corp1_id = advertisements(:corp1).advertisement_list.id
    corp2_id = advertisements(:corp2).advertisement_list.id
    xhr(:post, :update_sort_corp_advertisement, :corp_ads =>[corp1_id, corp2_id])
    assert_response(:success)
    assert_template('sort')
  end

  def test_update_sort_pref_advertisement
    setup_advertisement_list
    pref1_id = advertisements(:pref1).advertisement_list.id
    pref2_id = advertisements(:pref2).advertisement_list.id
    xhr(:post, :update_sort_pref_advertisement, :pref_ads =>[pref1_id, pref2_id])
    assert_response(:success)
    assert_template('sort')
  end

  def test_update_advertisemnt_preview
    setup_advertisement_list
    AdvertisementList.update_all("state = #{Advertisement::PUBLISHED}")
    post :update_advertisement, :preview => "プレビュー"
    assigns(:corp_ads).each do |ad|
      assert_equal Advertisement::OUTSIDE_TYPE, ad.side_type
    end
    assigns(:pref_ads).each do |ad|
      assert_equal Advertisement::INSIDE_TYPE, ad.side_type
    end
    assert_template('preview_banners')
  end

  def test_update_advertisemnt_cancel
    message = '設定変更を破棄しました。'
    setup_advertisement_list
    Advertisement.update_all("state = #{Advertisement::NOT_PUBLISHED}")

    post :update_advertisement, :cancel => "キャンセル"
    assert_redirected_to :action => 'list'
    assert_nil Job.find_by_action('move_banner_images')
    assert 0, AdvertisementList.count
    assert_equal message, flash[:advertisement_notice]
    Advertisement.find(:all).each do |ad|
      assert_equal Advertisement::NOT_PUBLISHED, ad.state
    end
  end

  def test_update_advertisemnt
    message = '現在、バナー広告の設定変更を反映中です。変更が反映されるまでバナー広告の設定はできません。'
    setup_advertisement_list
    Advertisement.update_all("state = #{Advertisement::NOT_PUBLISHED}")
    AdvertisementList.update_all("state = #{Advertisement::PUBLISHED}")
    post :update_advertisement, :save => "  保存  "
    assert_redirected_to :action => 'list'
    assert 0, AdvertisementList.count
    assert Job.find_by_action('move_banner_images')
    assert_equal message, flash[:advertisement_notice]
  end

  def test_check_advertisement_existence
    message =  'ページが存在しません'

    get :edit
    assert_equal message, flash[:advertisement_notice]
    assert_response(:redirect)
    assert_redirected_to :action => "list"

    get :show
    assert_equal message, flash[:advertisement_notice]
    assert_response(:redirect)
    assert_redirected_to :action => "list"

    get :change_image
    assert_equal message, flash[:advertisement_notice]
    assert_response(:redirect)
    assert_redirected_to :action => "list"

    post :update
    assert_equal message, flash[:advertisement_notice]
    assert_response(:redirect)
    assert_redirected_to :action => "list"

    get :delete
    assert_equal message, flash[:advertisement_notice]
    assert_response(:redirect)
    assert_redirected_to :action => "list"
  end

  def test_check_advertisement_list_existence
    message =  '公開作業を最初からやり直してください'

    AdvertisementList.destroy_all

    post :change_state
    assert_response(:redirect)
    assert_redirected_to :action => "list"
    assert_equal message, flash[:advertisement_notice]

    get :sort
    assert_response(:redirect)
    assert_redirected_to :action => "list"
    assert_equal message, flash[:advertisement_notice]

    xhr(:post, :update_sort_pref_advertisement)
    assert_response(:redirect)
    assert_redirected_to :action => "list"
    assert_equal message, flash[:advertisement_notice]

    xhr(:post, :update_sort_corp_advertisement)
    assert_response(:redirect)
    assert_redirected_to :action => "list"
    assert_equal message, flash[:advertisement_notice]

    post :update_advertisement
    assert_response(:redirect)
    assert_redirected_to :action => "list"
    assert_equal message, flash[:advertisement_notice]
  end

  def test_job_filter_published_page
    Advertisement.update(advertisements(:pref1).id, :state => Advertisement::PUBLISHED)
    Job.create(:action => 'move_banner_images',:datetime => Time.now)
    message = '現在、バナー広告の設定変更を反映中です。変更が反映されるまでバナー広告の設定はできません。'
   # test actions which get success response 
    get :list
    assert_response(:success)
    assert_template "list"
    assert_equal message, flash[:advertisement_notice]

    get :show, :id => advertisements(:pref1).id
    assert_response(:success)
    assert_template "show"
    assert_nil flash[:advertisement_notice]

    get :new
    assert_response(:success)
    assert_template "edit"
    assert_nil flash[:advertisement_notice]

    post :create, :advertisement => {
                      :name => "test",
                      :advertiser => "test",
                      :image_file => uploaded_file("#{RAILS_ROOT}/tmp/test.png", "image/png"),
                      :alt => "test file",
                      :url => "http://www.example.com",
                      :begin_date => Time.local(2006,1,9),
                      :end_date => Time.local(2006,2,9), 
                      :side_type => Advertisement::INSIDE_TYPE,
                      :show_in_header => true}
    assert_redirected_to :action => 'list'
    assert_not_equal message, flash[:advertisement_notice]
    
   # test actions which are redirected to list view.
    [:edit,:delete,:change_image].each do |action|
      get action, :id => advertisements(:pref1).id
      assert_redirected_to :action => 'list'
      assert_equal message, flash[:advertisement_notice]
    end

    post :update, :id => advertisements(:pref1).id
    assert_redirected_to :action => 'list'
    assert_equal message, flash[:advertisement_notice]

    [:set_state,:sort,:preview].each do |action|
      get action
      assert_redirected_to :action => 'list'
      assert_equal message, flash[:advertisement_notice]
    end

    [:change_state,:update_advertisement].each do |action|
      post action
      assert_redirected_to :action => 'list'
      assert_equal message, flash[:advertisement_notice]
    end

    [:update_sort_pref_advertisement,
     :update_sort_corp_advertisement].each do |action|
     xhr(:post, action)
      assert_redirected_to :action => 'list'
      assert_equal message, flash[:advertisement_notice]
    end
  end

  def test_expired_advertisement_exist
    Time.redefine_now(Time.mktime(2006, 2, 2))
    message = '公開期限切れの広告があります。'
    advertisement = Advertisement.find(advertisements(:pref1).id)
    advertisement.update_attributes(:end_date => Time.local(2006,2,1),
                                    :state => Advertisement::PUBLISHED)
    get :list
    assert_response :success
    assert_template 'list'
    assert_equal message, flash[:expired_advertisement_exist]
    Time.revert_now
  end


  private

  def setup_advertisement_list
    advertisements = Advertisement.find(:all)
    advertisements.each do |ad|
      ad.update_attributes(:state => Advertisement::PUBLISHED)
      AdvertisementList.create(:advertisement_id => ad.id,
                               :pref_ad_number => ad.pref_ad_number,
                               :corp_ad_number => ad.corp_ad_number)
    end
  end
end
