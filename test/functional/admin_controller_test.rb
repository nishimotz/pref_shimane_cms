require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'
require 'fileutils'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase
  fixtures :sections, :pages, :genres, :users, :divisions, :page_contents, :page_links

  def setup
    Time.redefine_now(Time.mktime(2006, 3, 13))

    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @aaa = Page.find(2)
    create_session

    FileUtils.mkdir("#{AdminController::FILE_PATH}/1")
    FileUtils.copy_file("#{RAILS_ROOT}/tmp/test.png", "#{AdminController::FILE_PATH}/1/1.png")
  end

  def teardown
    Time.revert_now
    FileUtils.rm_rf(Dir["#{AdminController::FILE_PATH}/[1-9]*"])
  end

  def test_index
    get(:index)
    assert_response(:success)
    assert_template('index')
  end

  def test_page
    get(:page)
    assert_response(:success)
    assert_template('page')
  end

  def test_genre
    get(:genre)
    assert_response(:success)
    assert_template('genre')
  end

  def test_list_page_status
    get(:list_page_status)
    assert_response(:success)
    assert_template('list_page_status')
  end

  def test_update_page_success
    post(:edit_page, :id => 1)
    assert_template('edit_page')
    post(:update_page, :id => 1,
         :content => {
           :content => %Q!<h1>見出し</h1>\n<p>本文<img style="width: 39px; height: 26px" class="invalid" src="/genre1/index.data/1.png" alt="1" /></p>!
         })
    assert_response(:redirect)
    assert_redirected_to(:action => 'show_page_info', :id => 1)
    priv_content = Page.find(1).private.content
    attributes = ['style="width: 39px; height: 26px"',
                  'src="/genre1/index.data/1.png"']
    attributes.each do |attr|
    assert_match(%r!<img [^>]*?#{Regexp.quote(attr)}[^>]*?>!, Page.find(1).private.content)
    end
  end

  def test_update_page_failure
    post(:update_page, :id => 1,
         :content => {
           :content => %Q!<p>本文<img src="/genre1/index.data/1.png" /></p>!
         })
    assert_response(:success)
    assert_template('edit_page')
    assert_equal('「画像の説明」のない画像があります',
                 assigns(:content).errors.on(:alt))
    assert_equal(%Q!<p>本文<img class="invalid" src="/genre1/index.data/1.png" /></p>\n!,
                 assigns(:content).content)
    post(:update_page, :id => 1,
         :content => {
           :content => %Q!<p>本文\342\205\240</p>!
         })
    assert_response(:success)
    assert_template('edit_page')
    assert_equal('機種依存文字があります：&#8544;',
                 assigns(:content).errors.on(:char))
    post(:update_page, :id => 1,
         :convert_char => 1,
         :content => {
           :content => %Q!<p>本文\342\210\256</p>!
         })
    assert_response(:success)
    assert_template('edit_page')
    assert_equal('変換できない機種依存文字があります：&#8750;',
                 assigns(:content).errors.on(:char))
    post(:update_page, :id => 1,
         :content => {
           :content => %Q!<p>本文\342\210\256</p>!
         })
    assert_response(:success)
    assert_template('edit_page')
    assert_equal('機種依存文字があります：&#8750;',
                 assigns(:content).errors.on(:char))
    assert_equal(%Q!<p>本文<span class="invalid">&#8750;</span></p>\n!,
                 assigns(:content).content)
    post(:update_page, :id => 1,
         :convert_char => 1,
         :content => {
           :content => %Q!<p>本文\342\205\240</p>!
         })
    assert_response(:success)
    assert_template('edit_page')
    assert_equal("機種依存文字を変換しました：\342\205\240→I",
                 assigns(:content).errors.on(:conv_char))
    assert_match(%r!本文I!, assigns(:content).content)
  end

  def test_create_page_failure
    page = pages(:genre1_2_page1)
    post(:create_page,
         :id => page.genre_id,
         :page => {:name => page.name, :title => page.title},
         :template_page => {:enable => 'off'})

    assert_response(:success)
    assert_template('new_page')
    assert_equal("そのページ名はすでに使われています",
                 assigns(:flash)[:name_notice])
    assert_equal("そのタイトルはすでに使われています",
                 assigns(:flash)[:title_notice])
    # validation page title
    post(:create_page,
         :id => page.genre_id,
         :page => {:name => 'test_invalid_page', :title => '⑤'},
         :template_page => {:enable => 'off'})
    assert_response(:success)
    assert_template('new_page')
    assert_equal("次の文字は機種依存文字です。(&#9316;)",
                 assigns(:flash)[:title_notice])
  end

  def test_create_page_success
    post(:create_page, :page => {:name => 'test10', :title => 'テスト10'}, :id => 2, :template_page => {:enable => 'off'})
    num = Page.find(:first, :order => 'id desc').id
    assert_redirected_to(:action => 'edit_page', :id => num, :status => 'new')
    assert_equal('test10', assigns(:page).name)
    post(:update_page,
         :content => {
           :content => "<h1>見出し</h1>\n<p>本文</p>"
         },
         :id => num)
    assert_redirected_to(:action => 'show_page_info', :id => num)
  end

  def test_cancel_page
    # create_page
    post(:create_page, :page => {:name => 'test20', :title => 'テスト20'}, :id => 2, :template_page => {:enable => 'off'})
    assert_response(:redirect)
    page = Page.find(:first, :order => 'id desc')
    assert_equal('test20', assigns(:page).name)
    post(:update_page, :status => 'new', :id => page.id, :cancel => 'aaa')
    assert_not_equal('test20', Page.find(:first, :order => 'id desc').name)

    # edit_page
    post(:edit_page, :id => 1)
    page = Page.find(1)
    post(:update_page, :id => 1, :commit => 'キャンセル')
    assert(Page.find(1))
  end

  def test_show_page
    get(:show_page, :id => 1)
    assert_response(:success)
    assert_template('show_page')
  end

  def test_import_failure
    post(:import, :id => 1)
    assert_response(:success)
    assert_template('edit_page')
    assert_equal('変換に失敗しました。', assigns(:flash)[:import_notice])
  end

  def test_succeed_to_update_private_page_status_with_valid_email
    Job.destroy_all
    page = Page.find(2)
    post(:update_private_page_status,
         :public_term => {:switch => "off"},
         :private => {
           :comment => 'some comment',
           :email => 'noreply',
           :section_news => PageContent::NEWS_YES,
           :admission => PageContent::PUBLISH},
         :id => page.contents[0].id
         )
    page.reload
    assert_response(:redirect)
    assert_equal(PageContent::PUBLISH, page.public.admission)
    assert_equal('some comment', page.public.comment)
    assert_equal('noreply', page.public.email)
    job = Job.find(:first, :order => 'id desc')
    assert_equal('create_page', job.action)
    assert_equal('2', job.arg1)
    assert_nil(job.arg2)
    assert_nil(Job.find_by_action('enable_remove_attachment'))
  end
  
  def test_fail_to_update_private_page_status_with_invalid_email
    Job.destroy_all
    page = Page.find(2)
    post(:update_private_page_status,
         :public_term => {:switch => "off"},
         :private => {
           :comment => 'some comment',
           :email => 'noreply@pref.shimane.lg.jp',
           :section_news => PageContent::NEWS_YES,
           :admission => PageContent::PUBLISH},
         :id => page.contents[0].id
         )
    page.reload
    assert_response(:success)
    assert_template("edit_private_page_status")
    assert_not_equal('noreply@pref.shimane.lg.jp', page.contents[0].email)
    job = Job.find(:first, :order => 'id desc')
    assert_nil(job)
  end

  def test_succeed_to_update_public_page_status_with_valid_email
    Job.destroy_all
    now = Time.now
    post(:update_public_page_status,
         :public => {
           :admission => PageContent::PUBLISH,
           :email => "noreply",
           :comment => 'another comment',
           'last_modified(1i)' => now.year,
           'last_modified(2i)' => now.month,
           'last_modified(3i)' => now.day,
           'last_modified(4i)' => now.hour,
           'last_modified(5i)' => now.min,
         },
         :id => Page.find(2).contents[0].id)
    assert_response(:redirect)
    page = Page.find(2)
    assert_equal(PageContent::PUBLISH, page.public.admission)
    assert_equal('another comment', page.public.comment)
    assert_equal('noreply', page.public.email)
    job = Job.find(:first, :order => 'id desc')
    assert_equal('create_page', job.action)
    assert_equal('2', job.arg1)
    assert_nil(job.arg2)
  end

  def test_fail_to_update_public_page_status_with_invalid_email
    Job.destroy_all
    now = Time.now
    post(:update_public_page_status,
         :public => {
           :admission => PageContent::PUBLISH,
           :email => "noreply@pref.shimane.lg.jp",
           :comment => 'another comment',
           'last_modified(1i)' => now.year,
           'last_modified(2i)' => now.month,
           'last_modified(3i)' => now.day,
           'last_modified(4i)' => now.hour,
           'last_modified(5i)' => now.min,
         },
         :id => Page.find(2).contents[0].id)
    assert_response(:success)
    assert_template("edit_public_page_status")
    page = Page.find(2)
    assert_not_equal('noreply@pref.shimane.lg.jp', page.contents[0].email)
    assert_nil(page.public)
    job = Job.find(:first, :order => 'id desc')
    assert_nil(job)
  end

  def test_update_private_page_status_admission
    # without remove_attachment
    Job.destroy_all
    page = Page.find(2)
    post(:update_private_page_status,
         :public_term => {:switch => "off"},
         :private => {
           :comment => 'some comment',
           :email => 'noreply',
           :section_news => PageContent::NEWS_YES,
           :admission => PageContent::PUBLISH},
         :id => page.contents[0].id
         )
    page.reload
    assert_response(:redirect)
    assert_equal(PageContent::PUBLISH, page.public.admission)
    assert_equal('some comment', page.public.comment)
    job1 = Job.find(:first, :order => 'id desc')
    assert_equal('create_page', job1.action)
    assert_equal('2', job1.arg1)
    assert_nil(job1.arg2)
    assert_nil(Job.find_by_action('enable_remove_attachment'))

    # with other page's remove_attachment
    page.reload
    Job.destroy_all
    Job.create(:action => 'remove_attachment',
               :arg1 => "/kochokoho/kawai.data/test.pdf",
               :datetime => Time.now + 60*60*24*3650) 
    post(:update_private_page_status,
         :public_term => {:switch => "off"},
         :private => {
           :comment => 'some comment',
           :email => 'noreply',
           :section_news => PageContent::NEWS_YES,
           :admission => PageContent::PUBLISH},
         :id => page.contents[0].id
         )
    page.reload
    assert_response(:redirect)
    assert_equal(PageContent::PUBLISH, page.public.admission)
    assert_equal('some comment', page.public.comment)
    job1 = Job.find(:first, :order => 'id desc')
    assert_equal('create_page', job1.action)
    assert_equal('2', job1.arg1)
    assert_nil(job1.arg2)
    assert_nil(Job.find_by_action('enable_remove_attachment'))

    # with remove_attachment
    page.reload
    Job.destroy_all
    Job.create(:action => 'remove_attachment',
               :arg1 => "#{page.path_base}.data/test.pdf",
               :datetime => Time.now + 60*60*24*3650) 
    post(:update_private_page_status,
         :public_term => {:switch => "off"},
         :private => {
           :comment => 'some comment',
           :email => 'noreply',
           :section_news => PageContent::NEWS_YES,
           :admission => PageContent::PUBLISH},
         :id => page.contents[0].id
         )
    page.reload
    assert_response(:redirect)
    assert_equal(PageContent::PUBLISH, page.public.admission)
    assert_equal('some comment', page.public.comment)
    job1, job2 = Job.find(:all, :order => 'id desc', :limit => 2)
    assert_equal('enable_remove_attachment', job1.action)
    assert_equal('/genre1/genre2/page1.data/', job1.arg1)
    assert_nil(job1.arg2)
    assert_equal('create_page', job2.action)
    assert_equal('2', job2.arg1)
    assert_nil(job2.arg2)

    # with remove_attachment and enable_remove_attachment
    remove_job_size = Job.find(:all, :conditions => ['action = ?',
                                 'enable_remove_attachment']).size
    post(:update_private_page_status,
         :public_term => {:switch => "off"},
         :private => {
           :comment => 'some comment',
           :email => 'noreply',
           :section_news => PageContent::NEWS_YES,
           :admission => PageContent::PUBLISH},
         :id => page.contents[0].id
         )
    page.reload
    assert_response(:redirect)
    assert_equal(PageContent::PUBLISH, page.public.admission)
    assert_equal('some comment', page.public.comment)
    job1 = Job.find(:first, :order => 'id desc')
    assert_equal('create_page', job1.action)
    assert_equal('2', job1.arg1)
    assert_nil(job1.arg2)
    new_remove_job_size = Job.find(:all, :conditions => ['action = ?',
                                 'enable_remove_attachment']).size
    assert_equal(new_remove_job_size, remove_job_size)
  end

  def test_update_private_page_status_cancel
    now = Time.now
    post(:update_public_page_status,
         :public => {
           :admission => PageContent::CANCEL,
           :comment => 'another comment',
           'last_modified(1i)' => now.year,
           'last_modified(2i)' => now.month,
           'last_modified(3i)' => now.day,
           'last_modified(4i)' => now.hour,
           'last_modified(5i)' => now.min,
         },
         :id => Page.find(2).contents[0].id)
    assert_response(:redirect)
    page = Page.find(2)
    assert_equal(PageContent::CANCEL, page.public.admission)
    assert_equal('another comment', page.public.comment)
    job = Job.find(:first, :order => 'id desc')
    assert_equal('cancel_page', job.action)
    assert_equal('2', job.arg1)
    assert_nil(job.arg2)
  end

  def test_update_public_page_status_public_cancel
    now = Time.now
    page = Page.find(2)
    page_content = page.contents[0]
    page_content.update_attributes(:begin_date => Time.now - 1,
                                   :end_date => Time.now + 2,
                                   :admission => PageContent::PUBLISH)
    page_content.publish
    # create waiting page
    waiting_page = page.private
    waiting_page.update_attributes(:begin_date => Time.now + 3,
                                   :end_date => Time.now + 4,
                                   :admission => PageContent::PUBLISH)
    waiting_page.publish
    post(:update_public_page_status,
         :public => {
           :admission => PageContent::CANCEL,
           :comment => 'another comment',
           'last_modified(1i)' => now.year,
           'last_modified(2i)' => now.month,
           'last_modifi
ed(3i)' => now.day,
           'last_modified(4i)' => now.hour,
           'last_modified(5i)' => now.min,
         },
         :id => page.contents[0].id)
    assert_response(:redirect)
    page.reload
    assert_equal(2, page.contents.size)
    assert_equal(PageContent::CANCEL, page.public_page.admission)
    assert_equal('another comment', page.public_page.comment)
    assert(page.waiting_page)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(1, create_jobs.size)
    assert_equal(2, cancel_jobs.size)
    assert_equal(waiting_page.begin_date, create_jobs[0].datetime)
    assert_equal(now, cancel_jobs[0].datetime)
    assert_equal(waiting_page.end_date, cancel_jobs[1].datetime)

    post(:update_public_page_status,
         :public => {
           :admission => PageContent::PUBLISH,
           :comment => 'yet another comment',
           'last_modified(1i)' => now.year,
           'last_modified(2i)' => now.month,
           'last_modified(3i)' => now.day,
           'last_modified(4i)' => now.hour,
           'last_modified(5i)' => now.min,
         },
         :id => page.public_page.id)
    assert_response(:redirect)
    page.reload
    assert_equal(PageContent::PUBLISH, page.public_page.admission)
    assert_equal('yet another comment', page.public_page.comment)
    assert(page.waiting_page)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(2, create_jobs.size)
    assert_equal(2, cancel_jobs.size)
    assert_equal(page_content.begin_date, create_jobs[0].datetime)
    assert_equal(waiting_page.begin_date, create_jobs[1].datetime)
    assert_equal(page_content.end_date, cancel_jobs[0].datetime)
    assert_equal(waiting_page.end_date, cancel_jobs[1].datetime)
  end

  def test_update_public_page_status_publish_reject
    now = Time.now
    page = Page.find(2)
    page_content = page.contents[0]
    page_content.update_attributes(:begin_date => Time.now - 1,
                                   :end_date => Time.now + 4,
                                   :admission => PageContent::PUBLISH)
    page_content.publish
    # create waiting page
    waiting_page = page.private
    waiting_page.update_attributes(:begin_date => Time.now + 3,
                                   :end_date => Time.now + 4,
                                   :admission => PageContent::PUBLISH)
    waiting_page.publish
    page.reload
    assert_equal(2, page.contents.size)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(1, create_jobs.size)
    assert_equal(page_content.end_date, cancel_jobs[0].datetime)
    assert_equal(1, cancel_jobs.size)
    assert_equal(page_content.end_date, cancel_jobs[0].datetime)

    post(:update_public_page_status,
         :public => {
           :admission => PageContent::PUBLISH_REJECT,
           :comment => 'another comment',
         },
         :id => waiting_page.id)
    waiting_page.reload
    assert_response(:redirect)
    page.reload
    assert_equal(PageContent::PUBLISH_REJECT, waiting_page.admission)
    assert_equal('another comment', waiting_page.comment)
    assert(!page.waiting_page)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert(create_jobs.empty?)
    assert_equal(1, cancel_jobs.size)
    assert_equal(page_content.end_date, cancel_jobs[0].datetime)
  end

  # genre
  def test_create_genre
    genre = genres(:top)
    child_count = genre.children.size
    post(:create_genre,
         :new_genre => {'name' => 'jyosys', 'title' => '情報政策課'},
         :id => genre.id)
    assert_equal(child_count + 1, Genre.find(genre.id).children.size)
    new_genre = Genre.find_by_path('/jyosys/')
    assert_equal(genre.section_id, new_genre.section_id)
    assert_equal('/jyosys/', new_genre.path)
    assert_redirected_to(:action => 'genre', :id => new_genre.parent_id.to_s)
  end

  def test_create_genre_failure
    genre = genres(:top)
    post(:create_genre,
         :new_genre => {'name' => '', 'title' => ''},
         :id => genre.id)
    assert_response(:success)
    assert_template('genre')
    assert_equal("URL名が正しくありません。半角英数字で入力してください",
                 assigns(:new_genre).errors.on(:name))
    assert_equal("タイトルが空です。",
                 assigns(:new_genre).errors.on(:title))
    # validation page title
    post(:create_genre,
         :new_genre => {'name' => 'aar2', 'title' => '⑤'},
         :id => genre.id)
    assert_response(:success)
    assert_template('genre')
    assert_equal("次の文字は機種依存文字です。(&#9316;)",
                 assigns(:new_genre).errors.on(:title))
  end

  def test_edit_genre
    genre = genres(:genre3)
    post(:edit_genre, :id => genre.id, :genre => {:title => 'テスト'})
    genre = Genre.find(genre.id)
    assert_equal('テスト', genre.title)
  end

  def test_destroy_genre
    genre = genres(:genre1)
    genre_pages = genre.all_pages
    genre_genres = genre.all_genres
    section = genre.section
    post(:destroy_genre, :id => genre.id)
    assert_nil Genre.find_by_id(genre.id)
    genre_genres.map {|g| g.id }.each do |id|
      assert_nil Page.find_by_id(id)
    end
    genre_pages.map {|p| p.id }.each do |id|
      assert_nil Page.find_by_id(id)
    end
    section.reload
    assert_nil section.top_genre_id
  end

  def test_update_genre_section
    genre = genres(:genre4)
    post(:update_genre_section, :id => genre.id,
         :genre => {:section_id => '3'})
    assert_redirected_to(:action => 'genre', :id => genre.id.to_s)
    genre = Genre.find(genre.id)
    assert_equal(3, genre.section_id)
  end

  def test_set_tracking_code
    post(:set_tracking_code, :id => 1, :genre => {:tracking_code => 'test'})
    assert_redirected_to(:action => 'genre')
    genre = Genre.find(1)
    assert_equal('test', genre.tracking_code)
  end

  def test_move
    get(:move)
    assert_response(:success)
    assert_template('move')
  end

  def test_genre_move_update_success
    page = Page.find(pages(:link_test_page).id)
    page_content = page.private
    page_content.update_attribute(:admission, 3)
    genre1 = genres(:genre3_1)
    genre1_parent_id = genre1.parent_id
    xhr(:post, :move_update, :id => genre1.id, :recv => genres(:genre2).id)
    assert_response(:success)
    assert_template(nil)
    genre = Genre.find(genre1.id)
    assert_not_equal(genre1_parent_id, genre.parent_id)
    assert_equal(genres(:genre2).id, genre.parent_id)
    page.reload
    public = page.public.content
    private = page.private.content
    assert_match(%r|/genre2/genre1/news.html|, public)
    assert_match(%r|/genre2/genre1/news.html|, private)
    assert_match(%r|/genre2/genre1/absolute_uri.html|, public)
    assert_match(%r|/genre2/genre1/absolute_uri.html|, private)
    assert_match(%r|/genre2/genre1/link_test.data/exist.png|, public)
    assert_match(%r|/genre2/genre1/link_test.data/exist.png|, private)
    assert_match(%r|/genre2/genre1/absolute_uri.data/nonexist.png|, public)
    assert_match(%r|/genre2/genre1/absolute_uri.data/nonexist.png|, private)
    assert_equal('/genre2/genre1/news.html', page_links(:id_46).link)
    assert_match('/genre2/genre1/saisaku/link_test.html', page_links(:id_44).link)
    assert_equal('/genre2/genre1/absolute_uri.html', page_links(:id_45).link)
    assert_match('/genre2/genre1/relative_uri.png', page_links(:id_49).link)
    job1, job2 = Job.find(:all, :order => 'id desc', :limit => 2)
    assert_equal('create_page', job1.action)
    assert_equal('move_folder', job2.action)
    assert_equal('/genre2/genre1/', job2.arg1)
    assert_equal('/genre3/genre1/', job2.arg2)
  end

  def test_page_move_update_success
    page = Page.find(pages(:link_test_page).id)
    page_content = page.private
    page_content.update_attribute(:admission, 3)
    genre1 = genres(:genre3_1)
    xhr(:post, :move_update, :id => "page-#{page.id}",
        :recv => genres(:genre3).id)
    assert_response(:success)
    assert_template(nil)
    page = Page.find(page.id)
    public = page.public.content
    private = page.private.content
    assert_equal(genres(:genre3).id, page.genre_id)
    assert_equal('/genre3/link_test.html', page.path)
    assert_match(%r|/genre3/link_test.html|, private)
    assert_match(%r|/genre3/link_test.html|, public)
    assert_match(%r|/genre3/link_test.data/exist.png|, private)
    assert_match(%r|/genre3/link_test.data/exist.png|, public)
    job1, job2 = Job.find(:all, :order => 'id desc', :limit => 2)
    assert_equal('create_page', job1.action)
    assert_equal('move_page', job2.action)
    assert_equal('/genre3/', job2.arg1)
    assert_equal('/genre3/genre1/link_test.html', job2.arg2)
  end

  def test_genre_move_update_failure_page_under_edit
    job_count = Job.count
    genre1 = genres(:genre3_1)
    xhr(:post, :move_update, :id => genre1.id, :recv => genres(:genre2).id)
    assert_response(:success)
    assert_template(nil)
    assert_equal "移動するフォルダの中に未公開ページがあるため、フォルダの移動ができませんでした。未公開ページを公開してから、作業をやり直してください。" , flash[:page_editing_notice]
    genre1_parent_id = genre1.parent_id
    genre = Genre.find(genre1.id)
    assert_equal(genre1_parent_id, genre.parent_id)
    assert_equal(job_count, Job.count)
  end

  def test_page_move_update_failure_page_under_edit
    job_count = Job.count
    page = Page.find(pages(:link_test_page).id)
    genre1 = genres(:genre3_1)
    xhr(:post, :move_update, :id => "page-#{page.id}",
        :recv => genres(:genre3).id)
    page = Page.find(page.id)
    assert_response(:success)
    assert_template(nil)
    assert_equal "未公開ページがあるため、ページの移動ができませんでした。未公開ページを公開してから、作業をやり直してください。" , flash[:page_editing_notice]
    genre = Genre.find(genre1.id)
    assert_equal(genre.id, page.genre_id)
    assert_equal(job_count, Job.count)
  end

  def test_move_update_failure_loop
    job_count = Job.count
    genre1 = genres(:genre2)
    genre1_parent_id = genre1.parent_id
    xhr(:post, :move_update, :id => genre1.id, :recv => genres(:genre2_2).id)
    assert_response(:success)
    assert_template(nil)
    genre = Genre.find(genre1.id)
    assert_equal(genre1_parent_id, genre.parent_id)
    assert_equal(job_count, Job.count)
  end

  def test_move_update_failure_same_name
    job_count = Job.count
    genre1 = genres(:genre2_2)
    genre1_parent_id = genre1.parent_id
    xhr(:post, :move_update, :id => genre1.id, :recv => genres(:genre1).id)
    assert_response(:success)
    assert_template(nil)
    genre = Genre.find(genre1.id)
    assert_equal(genre1_parent_id, genre.parent_id)
    assert_equal(job_count, Job.count)
    page1 = pages(:genre1_2_3_page1)
    page1_genre_id = page1.genre_id
    xhr(:post, :move_update, :id => "page-#{page1.id}", :recv => genres(:genre1_2).id)
    assert_response(:success)
    assert_template(nil)
    page = Page.find(page1.id)
    assert_equal(page1_genre_id, page.genre_id)
    assert_equal(job_count, Job.count)
  end

  def test_update_public_term_success
    begin_date = Time.now
    end_date = Time.now + 86400
    post(:update_private_page_status,
         :private => {
           :email => "noreply",
           'begin_date(1i)' => begin_date.year,
           'begin_date(2i)' => begin_date.month,
           'begin_date(3i)' => begin_date.day,
           'begin_date(4i)' => begin_date.hour,
           'begin_date(5i)' => begin_date.min,
           'end_date(1i)' => end_date.year,
           'end_date(2i)' => end_date.month,
           'end_date(3i)' => end_date.day,
           'end_date(4i)' => end_date.hour,
           'end_date(5i)' => end_date.min,
           :section_news => PageContent::NEWS_YES,
         },
         :public_term => {:switch => 'on', :end_date_enable => 'on'},
         :id => 1)
    assert_response(:redirect)
    page = Page.find(1).private
    assert(page.begin_date)
    assert(page.end_date)
  end

  def test_update_public_term_failure
    page_content = Page.find(1).private
    begin_date = Time.now + 86400
    end_date = Time.now
    post(:update_private_page_status,
         :private => {
           'begin_date(1i)' => begin_date.year,
           'begin_date(2i)' => begin_date.month,
           'begin_date(3i)' => begin_date.day,
           'begin_date(4i)' => begin_date.hour,
           'begin_date(5i)' => begin_date.min,
           'end_date(1i)' => end_date.year,
           'end_date(2i)' => end_date.month,
           'end_date(3i)' => end_date.day,
           'end_date(4i)' => end_date.hour,
           'end_date(5i)' => end_date.min,
           :section_news => PageContent::NEWS_YES,
         },
         :public_term => {:switch => "on"},
         :id => 1)
    assert_not_equal(page_content.begin_date, begin_date)
    assert_not_equal(page_content.end_date, end_date)
  end

  def test_destroy_public_term_published_page
    page = Page.find(30)
    page_content = page.contents[0]
    page_content.begin_date = Time.now - 1
    page_content.end_date = Time.now + 1
    page_content.save
    page.reload
    assert(page.public_page.public_term_enable?)
    assert_nil(Job.find_by_arg1(page.id))
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page.public.end_date)
    assert(Job.find_by_action_and_arg1('cancel_page', page.id))

    get(:destroy_public_term, :id => page_content.id)
    page.reload
    assert_nil(page.public.begin_date)
    assert_nil(page.public.end_date)
    assert_nil(Job.find_by_arg1(page.id))

    # with waiting page
    Job.destroy_all
    # create current page
    cancel_page = page.contents[0]
    cancel_page.update_attributes(:begin_date => Time.now - 1,
                                   :end_date => Time.now + 1,
                                   :admission => PageContent::PUBLISH)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page_content.end_date)
    # create waiting page
    waiting_page = page.private
    waiting_page.update_attributes(:begin_date => Time.now + 2,
                                  :end_date => Time.now + 3,
                                  :admission => PageContent::PUBLISH)
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => waiting_page.begin_date)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => waiting_page.end_date)
    page.reload
    assert_equal(2, page.contents.size)
    assert(page.current)
    assert(page.waiting_page)

    get(:destroy_public_term, :id => cancel_page.id)
    page.reload
    assert(page.current)
    assert(page.waiting_page)
    assert_nil(page.public.begin_date)
    assert_nil(page.public.end_date)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(1, create_jobs.size)
    assert_equal(1, cancel_jobs.size)
    assert_equal(create_jobs[0].datetime, waiting_page.begin_date)
    assert_equal(cancel_jobs[0].datetime, waiting_page.end_date)
  end

  def test_destroy_public_term_expired_page
    page = Page.find(30)
    page_content = page.contents[0]
    page_content.begin_date = Time.now - 2
    page_content.end_date = Time.now - 1
    page_content.save
    page.reload
    assert_nil(Job.find_by_arg1(page.id))
    assert(!page.public_page.public_term_enable?)

    get(:destroy_public_term, :id => page_content.id)
    page.reload
    assert_nil(page.public.begin_date)
    assert_nil(page.public.end_date)
    jobs = Job.find(:all, :conditions => ['arg1 = ?', page.id],
                    :order => 'id desc')
    assert_equal(1,jobs.size)
    assert_equal('create_page',jobs.first.action)
    assert_equal(Time.now, jobs.first.datetime)

    # with waiting page
    Job.destroy_all
    # create current page
    cancel_page = page.contents[0]
    cancel_page.update_attributes(:begin_date => Time.now - 2,
                                   :end_date => Time.now - 1,
                                   :admission => PageContent::PUBLISH)
    # create waiting page
    waiting_page = page.private
    waiting_page.update_attributes(:begin_date => Time.now + 2,
                                  :end_date => Time.now + 3,
                                  :admission => PageContent::PUBLISH)
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => waiting_page.begin_date)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => waiting_page.end_date)
    page.reload
    assert_equal(2, page.contents.size)
    assert(!page.public_page.public_term_enable?)
    assert(page.waiting_page)

    get(:destroy_public_term, :id => cancel_page.id)
    page.reload
    assert(page.current)
    assert(page.waiting_page)
    assert_nil(page.public.begin_date)
    assert_nil(page.public.end_date)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(2, create_jobs.size)
    assert_equal(1, cancel_jobs.size)
    assert_equal(Time.now, create_jobs[0].datetime)
    assert_equal(waiting_page.begin_date, create_jobs[1].datetime)
    assert_equal(waiting_page.end_date, cancel_jobs[0].datetime)
  end

  def test_destroy_public_term_canceled_page_expired
    page = Page.find(30)
    page_content = page.contents[0]
    page_content.begin_date = Time.now - 2
    page_content.end_date = Time.now - 1
    page_content.admission = PageContent::CANCEL
    page_content.save
    page.reload
    assert_nil(Job.find_by_arg1(page.id))
    assert_nil(page.current)
    get(:destroy_public_term, :id => page_content.id)
    page.reload
    assert_nil(page.public.begin_date)
    assert_nil(page.public.end_date)
    jobs = Job.find(:all, :conditions => ['arg1 = ?', page.id],
                    :order => 'id desc')
    assert(jobs.empty?)

    # with waiting page
    Job.destroy_all
    # create current page
    cancel_page = page.contents[0]
    cancel_page.update_attributes(:begin_date => Time.now - 2,
                                   :end_date => Time.now - 1,
                                   :admission => PageContent::CANCEL)
    # create waiting page
    waiting_page = page.private
    waiting_page.update_attributes(:begin_date => Time.now + 2,
                                  :end_date => Time.now + 3,
                                  :admission => PageContent::PUBLISH)
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => waiting_page.begin_date)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => waiting_page.end_date)
    page.reload
    assert_equal(2, page.contents.size)
    assert(!page.public_page.public_term_enable?)
    assert(page.waiting_page)

    get(:destroy_public_term, :id => cancel_page.id)
    page.reload
    assert(!page.current)
    assert(page.waiting_page)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(1, create_jobs.size)
    assert_equal(1, cancel_jobs.size)
    assert_equal(waiting_page.begin_date, create_jobs[0].datetime)
    assert_equal(waiting_page.end_date, cancel_jobs[0].datetime)
  end

  def test_destroy_public_term_canceled_page_term_enabled
    page = Page.find(30)
    page_content = page.contents[0]
    page_content.update_attributes(:begin_date => Time.now - 1,
                                   :end_date => Time.now + 1,
                                   :admission => PageContent::CANCEL)
    page.reload
    assert_nil(page.current)
    assert_nil(Job.find_by_arg1(page.id))
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page.public.end_date)
    get(:destroy_public_term, :id => page_content.id)
    page.reload
    assert(page.current)
    assert_nil(page.public.begin_date)
    assert_nil(page.public.end_date)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id])
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_jobs', page.id])
    assert_equal(1, create_jobs.size)
    assert(cancel_jobs.empty?)
    assert_equal(Time.now, create_jobs.first.datetime)

    # with waiting page
    Job.destroy_all
    page.reload
    cancel_page = page.contents[0]
    cancel_page.update_attributes(:begin_date => Time.now - 1,
                                   :end_date => Time.now + 1,
                                   :admission => PageContent::CANCEL)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page_content.end_date)
    waiting_page = page.private
    waiting_page.update_attributes(:begin_date => Time.now + 2,
                                  :end_date => Time.now + 3,
                                  :admission => PageContent::PUBLISH)
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => waiting_page.begin_date)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => waiting_page.end_date)
    page.reload
    assert_equal(2, page.contents.size)
    assert_nil(page.current)
    get(:destroy_public_term, :id => cancel_page.id)
    page.reload
    assert(page.current)
    assert(page.waiting_page)
    assert_nil(page.public.begin_date)
    assert_nil(page.public.end_date)
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(2, create_jobs.size)
    assert_equal(1, cancel_jobs.size)
    assert_equal(create_jobs[0].datetime, Time.now)
    assert_equal(create_jobs[1].datetime, waiting_page.begin_date)
    assert_equal(cancel_jobs[0].datetime, waiting_page.end_date)
  end

  def test_destroy_public_term_waiting_page
    page = Page.find(30)
    page_content = page.contents[0]
    page_content.begin_date = Time.now + 1
    page_content.end_date = Time.now + 2
    page_content.save
    page.reload
    assert_nil(Job.find_by_arg1(page.id))
    assert_equal(page_content, page.waiting_page)
    # waiting_page jobs
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => page.public.begin_date)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page.public.end_date)
    Job.create(:action => 'enable_remove_attachment',
               :arg1 => page.path_base + '.data/',
               :datetime => page.public.begin_date)
    # other jobs
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => page.public.begin_date + 1)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page.public.end_date + 1)

    get(:destroy_public_term, :id => page_content.id)
    page.reload
    assert_nil(page.public.begin_date)
    assert_nil(page.public.end_date)
    jobs = Job.find(:all, :conditions => ['arg1 = ?', page.id],
                    :order => 'id desc')
    assert_equal(1,jobs.size)
    assert_equal('create_page',jobs.first.action)
    assert_equal(Time.now, jobs.first.datetime)
    jobs = Job.find(:all, :conditions => ['action = ?', 'enable_remove_attachment'])
    assert_equal(1,jobs.size)
    assert_equal('/not_enable.data/',jobs.first.arg1)
    assert_equal(Time.now, jobs.first.datetime)
  end

  def test_destroy_page
    page = Page.new(:name => 'destroy_test',
                    :title => 'ページ削除のテスト',
                    :genre_id => 1)
    page.save
    page_id = page.id
    page_content = PageContent.new(:content => 'なし')
    page.contents << page_content
    page_content_id = page.contents[0].id
    page_path = page.path
    get(:destroy_page, :id => page_id)
    assert_equal(false, Page.exists?(page_id))
    assert_equal(false, PageContent.exists?(page_content_id))
    job = Job.find(:all, :order => 'id desc')
    assert_equal(page_path, job[0].arg1)
    assert_equal('delete_page', job[0].action)
    assert_nil(job[0].arg2)
  end

  def test_destroy_page_failure
    user = users(:normal_user)
    @request.session[:user] = user
    page = Page.new(:name => 'destroy_test_failure',
                    :title => 'ページ削除のテスト',
                    :genre_id => user.genres.first.id)
    assert(page.save)
    page.contents[0].admission = PageContent::PUBLISH_REQUEST
    assert(page.contents[0].save)
    get(:destroy_page, :id => page.id)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    assert_equal('現在、ページの削除はできません。', assigns(:flash)[:error])
  end

  def test_list_file
    get(:list_file, :id => 1)
    assert_equal('1.png', File.basename(assigns(:list).first))
  end

  def test_upload_file_success
    page_id = 2
    path = "#{AdminController::FILE_PATH}/#{page_id}"
    post(:upload_file, :id => page_id, :file => {:content => uploaded_file("#{RAILS_ROOT}/README", 'text/plain', 'README.pdf')})
    assert_response(:redirect)
    assert(File.exist?("#{path}/README.pdf"))
  end

  def test_upload_top_page_success
    page = pages(:top_page)
    path = "#{AdminController::FILE_PATH}/#{page.id}"
    file_name = CMSConfig[:top_page_image]
    file_path = "#{AdminController::FILE_PATH}/CMSConfig[:top_page_picture]"
    File.open(file_path, 'w') do |file|
      file.print 'a' * 1024 * 51
    end
    post(:upload_file, :id => page.id, :file => {:content => uploaded_file(file_path, 'text/plain', file_name)})
    assert_response(:redirect)
    assert(File.exist?("#{AdminController::FILE_PATH}/#{page.id}/#{file_name}"))
  ensure
    File.unlink(file_path) if File.exist?(file_path)
  end

  def test_upload_file_failure
    page_id = 2
    path = "#{AdminController::FILE_PATH}/#{page_id}"
    File.open("#{AdminController::FILE_PATH}/test_over_file", 'w') do |file|
      file.print 'a' * (1024 * 1024 * 3 + 1)
    end
    post(:upload_file, :id => page_id, :file => {:content => uploaded_file("#{AdminController::FILE_PATH}/test_over_file", 'text/plain', 'test_over_file.jpg')})
    assert_response(:success)
    assert_equal('アップロードする画像ファイルのサイズが50KByteの上限を越えています', assigns(:error))
#    assert_equal('画像ファイルの合計サイズが3MByteの上限を越えますのでファイルを削除してからアップロードしてください', assigns(:error))
    assert(!File.exist?("#{path}/test_over_file"))
    File.unlink("#{AdminController::FILE_PATH}/test_over_file")
    post(:upload_file, :id => page_id, :file => {:content => uploaded_file("#{RAILS_ROOT}/README", 'text/plain', '日本語ファイル名.pdf')})
    assert_response(:success)
    assert_equal('ファイル名は半角英数字のみにしてください', assigns(:error))
  end

  def test_upload_file_failure2
    page_id = 2
    path = "#{AdminController::FILE_PATH}/#{page_id}"
    File.open("#{AdminController::FILE_PATH}/test_50kb_file", 'w') do |file|
      file.print 'a' * 1024 * 50
    end
    61.times do |i|
      post(:upload_file, :id => page_id, :file => {:content => uploaded_file("#{AdminController::FILE_PATH}/test_50kb_file", 'text/plain', "test_50kb_file_#{i}.jpg")})
      assert_response(:redirect)
    end
    post(:upload_file, :id => page_id, :file => {:content => uploaded_file("#{AdminController::FILE_PATH}/test_50kb_file", 'text/plain', 'test_50kb_file_61.jpg')})
    assert_response(:success)
    assert_equal('画像ファイルの合計サイズが3MByteの上限を越えますのでファイルを削除してからアップロードしてください', assigns(:error))
    assert(File.exist?("#{path}/test_50kb_file_60.jpg"))
    assert(!File.exist?("#{path}/test_50kb_file_61.jpg"))
  end

  def test_destroy_file
    page_id = 1
    page = Page.find(page_id)
    path = "#{AdminController::FILE_PATH}/#{page_id}"
    post(:upload_file, :id => page_id, :file => {:content => uploaded_file("#{RAILS_ROOT}/README", 'text/plain', 'README.doc')})
    assert(File.exist?("#{path}/README.doc"))
    get(:destroy_file, :id => page_id, :filename => 'README.doc')
    assert_redirected_to(:action => 'list_file', :id => page_id)
    assert(!File.exist?("#{path}/README.doc"))
  end

  def test_destroy_file_pdf_with_current
    page_id = 1
    page = Page.find(page_id)
    assert_not_nil(page.current)
    data_path = page.genre.path + page.name + '.data'
    path = "#{AdminController::FILE_PATH}/#{page_id}"
    post(:upload_file, :id => page_id, :file => {:content => uploaded_file("#{RAILS_ROOT}/README", 'text/plain', 'README.pdf')})
    assert(File.exist?("#{path}/README.pdf"))
    get(:destroy_file, :id => page_id, :filename => 'README.pdf')
    assert_redirected_to(:action => 'list_file', :id => page_id)
    assert(!File.exist?("#{path}/README.pdf"))
    job = Job.find(:first, :order => 'id desc')
    assert_equal('remove_attachment', job.action)
    assert_equal("#{data_path}/README.pdf", job.arg1)
  end

  def test_destroy_file_pdf_without_current
    page_id = 2
    page = Page.find(page_id)
    assert_nil(page.current)
    data_path = page.genre.path + page.name + '.data'
    path = "#{AdminController::FILE_PATH}/#{page_id}"
    post(:upload_file, :id => page_id, :file => {:content => uploaded_file("#{RAILS_ROOT}/README", 'text/plain', 'README.pdf')})
    assert(File.exist?("#{path}/README.pdf"))
    get(:destroy_file, :id => page_id, :filename => 'README.pdf')
    assert_redirected_to(:action => 'list_file', :id => page_id)
    assert(!File.exist?("#{path}/README.pdf"))
    job = Job.find(:first, :order => 'id desc')
    assert_not_equal('remove_attachment', job.action)
  end

  def test_create_alias
    post(:create_alias, :id => 2, :alias => {:title => 'てすと'})
    genre = Genre.find(:all, :order => 'id').last
    assert_equal('てすと', genre.title)
    assert_equal(2, genre.original_id)
  end

  def test_destroy_alias
    post(:create_alias, :id => 2, :alias => {:title => 'てすと'})
    genre = Genre.find(:all, :order => 'id').last
    id = genre.id
    get(:destroy_alias, :id => id)
    assert(!Genre.exists?(id))
  end

  def test_config
    get(:config)
    assert_response(:success)
    assert_template('config')
  end

  def test_edit_section_info
    get(:edit_section_info)
    assert_response(:success)
    assert_template('edit_section_info')
  end

  def test_list_info
    get(:list_info)
    assert_response(:success)
    assert_template('list_info')
  end

  # manage section
  def test_list_section
    get(:list_section)
    assert_response(:success)
    assert_template('list_section')
    assert_not_nil(assigns(:sections))
  end

  def test_new_section
    get(:new_section)
    assert_response(:success)
    assert_template('new_section')
    assert_not_nil(assigns(:section))
  end

  def test_create_section
    num_sections = Section.count
    post(:create_section,
         :section => {:division_id => 1,
                      :name => "test",
                      :code => "123456"},
         :genre => {:name => "test_genre"})
    assert_response(:redirect)
    assert_redirected_to(:action => 'list_section')
    assert_equal(num_sections + 1, Section.count)
  end

  def test_edit_section
    get(:edit_section, :id => 1)
    assert_response(:success)
    assert_template('edit_section')
    assert_not_nil(assigns(:section))
    assert(assigns(:section).valid?)
  end

  def test_update_section
    post(:update_section, :id => 1,
                          :genre => {:id => 3},
                          :section => {:code => 100,
                                       :division_id => 2,
                                       :name => "section_1"})
    assert_redirected_to(:action => 'list_section')
    assert_equal 3, Section.find(1).top_genre_id
  end

  def test_update_section_top_genre_nil
    post(:update_section, :id => 1,
                          :genre => {:id => nil},
                          :section => {:code => 100,
                                       :division_id => 2,
                                       :name => "section_1"})
    assert_redirected_to(:action => 'list_section')
    assert_nil Section.find(1).top_genre_id
  end

  def test_destroy_section
    section_genre = Genre.find_all_by_section_id(1)
    assert_not_nil Section.find(1)
    post(:destroy_section, :id => 1)
    assert_response(:redirect)
    assert_redirected_to(:action => 'list_section')
    assert_raise(ActiveRecord::RecordNotFound) { Section.find(1) }
    section_genre.each do |genre|
      genre.reload
      assert_equal Section::SUPER_SECTION, genre.section_id
    end
  end

  def test_update_section_info
    @request.session[:user] = users(:section_manager)
    post(:update_section_info, :id => 1,
         :section => {
           :info => '連絡先テスト'
         })
    job = Job.find(:first, :order => 'id desc')
    assert_equal('create_all_section_page', job.action)
    assert_equal('1', job.arg1)
    assert_nil(job.datetime)
    assert_response(:redirect)
    assert_redirected_to(:action => 'edit_section_info')
    assert_equal('連絡先テスト', Section.find(1).info)
  end

  def test_edit_mobile_page
    get(:copy_to_mobile, :id => 1)
    get(:edit_mobile_page, :id => 1)
    assert( assigns(:content).mobile)
  end

  def test_update_mobile_page
    get(:update_mobile_page, :id => 1, :commit => 'update',
        :content => {:mobile => '携帯向けです'})
    assert_redirected_to(:action => 'show_page_info', :id => 1)
    assert_equal('携帯向けです', Page.find(1).private.mobile)
    post(:update_mobile_page, :id => 1,
         :content => {
           :mobile => %Q!<p>本文<img src="/genre1/index.data/1.png" /></p>!
         })
    assert_redirected_to(:action => 'show_page_info', :id => 1)
    assert_equal("<p>本文</p>\n", Page.find(1).private.mobile)
  end

  def test_update_mobile_page_failure
    post(:update_mobile_page, :id => 1,
         :content => {
           :mobile => %Q!<p>本文\342\205\240</p>!
         })
    assert_response(:success)
    assert_template('edit_mobile_page')
    assert_equal('機種依存文字があります：&#8544;',
                 assigns(:content).errors.on(:char))
    post(:update_mobile_page, :id => 1,
         :convert_char => 1,
         :content => {
           :mobile => %Q!<p>本文\342\210\256</p>!
         })
    assert_response(:success)
    assert_template('edit_mobile_page')
    assert_equal('変換できない機種依存文字があります：&#8750;',
                 assigns(:content).errors.on(:char))
    post(:update_mobile_page, :id => 1,
         :content => {
           :mobile => %Q!<p>本文\342\210\256</p>!
         })
    assert_response(:success)
    assert_template('edit_mobile_page')
    assert_equal('機種依存文字があります：&#8750;',
                 assigns(:content).errors.on(:char))
    assert_equal(%Q!<p>本文<span class="invalid">&#8750;</span></p>\n!,
                 assigns(:content).mobile)
    post(:update_mobile_page, :id => 1,
         :convert_char => 1,
         :content => {
           :mobile => %Q!<p>本文\342\205\240</p>!
         })
    assert_response(:success)
    assert_template('edit_mobile_page')
    assert_equal("機種依存文字を変換しました：\342\205\240→I",
                 assigns(:content).errors.on(:conv_char))
    assert_match(%r!本文I!, assigns(:content).mobile)
  end

  def test_copy_to_mobile
    page = Page.find(1)
    content = page.private
    content.content = '携帯向けコンテンツ'
    content.save
    get(:copy_to_mobile, :id => 1)
    assert_equal('携帯向けコンテンツ', assigns(:content).mobile)
  end

  def test_prepare
    #for user whose section has section_top_genre
    user = users(:normal_user)
    section_top_genre = user.section.genre
    @request.session[:user] = user
    get(:page)
    assert_equal([2, 5, 7, 67, 68, 72, 73],
                assigns(:root_dir_list).collect{|i| i.id}.sort)
    assert_equal(assigns(:root_dir_list).last, section_top_genre)

    #for user whose section does not have any section_top_genre
    user = users(:section1_2_user)
    @request.session[:user] = user
    get(:page)
    assert_equal([9], assigns(:root_dir_list).collect{|i| i.id}.sort)
  end

  def test_update_title_success
    post(:update_title, :id => 1, :page => {:title => '変更'})
    assert_response(:redirect)
    page = Page.find(1)
    assert_equal('変更', page.title)
  end

  def test_update_title_failure
    post(:update_title, :id => 1, :page => {:title => ''})
    assert_response(:success)
    assert_equal('タイトルを入力してください',
                 assigns(:page).errors.on(:title))
  end

  def test_update_passwd_success
    # 正しい新しいパスワードを入力した時
    post(:update_passwd,
         :now => {:passwd => 'test'},
         :new => {
           :password => 'testtest10',
           :password_confirmation => 'testtest10'}
         )
    assert_response(:redirect)
    assert_redirected_to(:action => 'index')
    assert(User.authenticate('super_user', 'testtest10'))
    # 現在のパスワードが正しくない時
    post(:update_passwd,
         :now => {:passwd => 'test22'},
         :new => {
           :password => 'testtest11',
           :password_confirmation => 'testtest11'}
         )
    assert_response(:success)
    assert_template('edit_passwd')
    # 新しいパスワードが正しくない時
    @request.session[:user] = User.authenticate('super_user', 'testtest10')
    post(:update_passwd,
         :now => {:passwd => 'testtest10'},
         :new => {
           :password => 'testtest11',
           :password_confirmation => 'testtest12'}
         )
    assert_response(:success)
    assert_template('edit_passwd')
    # 新しいパスワードの文字数が正しくないとき(8〜でない)
    @request.session[:user] = User.authenticate('super_user', 'testtest10')
    post(:update_passwd,
         :now => {:passwd => 'testtest10'},
         :new => {
           :password => 'test',
           :password_confirmation => 'test1'}
         )
    assert(User.authenticate('super_user', 'testtest10'))
    # 新しいパスワードの文字数が正しくないとき(〜12でない)
    @request.session[:user] = User.authenticate('super_user', 'testtest10')
    post(:update_passwd,
         :now => {:passwd => 'testtest10'},
         :new => {
           :password => 'testtesttesttesttest',
           :password_confirmation => 'testtesttesttesttest'}
         )
    assert(User.authenticate('super_user', 'testtest10'))
  end

  def test_update_passwd_cancel
    post(:update_passwd, :cancel => 'on')
    assert_response(:redirect)
    assert_redirected_to(:action => 'index')
  end

  def test_list_user
    section = Section.find(1)
    get(:list_user, :id => section.id)
    assert_equal(section.users, assigns(:manage_users))
  end

  def test_create_user
    # ユーザ作成成功
    post(:create_user, :id => 1,
         :manage_user => {
           :name => 'テスト',
           :login => 'testuser',
           :password => 'testtest20',
           :password_confirmation => 'testtest20',
           :mail => "noreply@#{CMSConfig[:mail_domain]}"
         }
         )
    assert_response(:redirect)
    assert_redirected_to(:action => 'list_user', :id => 1)
    # ユーザ作成失敗(名前が空)
    post(:create_user, :id => 1,
         :manage_user => {
           :name => nil,
           :login => 'test',
           :password => 'testtest20',
           :password_confirmation => 'testtest20',
         }
         )
    assert_response(:success)
    assert_template('new_user')
    # ユーザ作成失敗(パスワードが空)
    post(:create_user, :id => 1,
         :manage_user => {
           :name => 'テスト',
           :login => 'test',
           :password => nil,
           :password_confirmation => 'testtest202020',
         }
         )
    assert_response(:success)
    assert_template('new_user')
    # ユーザ作成失敗(パスワードが長い)
    post(:create_user, :id => 1,
         :manage_user => {
           :name => 'テスト',
           :login => 'test',
           :password => 'testtest202020',
           :password_confirmation => 'testtest202020',
           :mail => nil
         }
         )
    assert_response(:success)
    assert_template('new_user')
  end

  def test_update_user
    # ユーザ変更成功
    user = users(:normal_user)
    post(:update_user, :id => user.id,
         :manage_user => {
           :name => 'テスト',
           :login => 'testuser',
           :password => 'testtest20',
           :password_confirmation => 'testtest20',
           :mail => "noreply@#{CMSConfig[:mail_domain]}"
         }
         )
    assert_response(:redirect)
    assert_redirected_to(:action => 'list_user', :id => user.section_id)
    # ユーザ変更成功(空のパスワードでパスワードを変更しない場合)
    post(:update_user, :id => user.id,
         :manage_user => {
           :name => 'テスト',
           :login => 'testuser',
           :password => '',
           :password_confirmation => '',
         }
         )
    assert_response(:redirect)
    assert_redirected_to(:action => 'list_user', :id => 1)
    assert(User.authenticate('testuser', 'testtest20'))
    # ユーザ変更失敗(nameが空)
    post(:update_user, :id => 1,
         :manage_user => {
           :name => '',
           :login => 'testuser',
           :password => '2222222222',
           :password_confirmation => '2222222222',
         }
         )
    assert_response(:success)
    assert_template('edit_user')
    # ユーザ変更失敗(パスワードが違う)
    post(:update_user, :id => 1,
         :manage_user => {
           :name => 'テスト',
           :login => 'testuser',
           :password => 'avcsefgdsa',
           :password_confirmation => '2222222222',
         }
         )
    assert_response(:success)
    assert_template('edit_user')
  end

  def test_destroy_user
    user = User.find(:all).last
    user_id = user.id
    section_id = user.section_id
    get(:destroy_user, :id => user_id)
    assert_response(:redirect)
    assert_redirected_to(:action => 'list_user', :id => section_id)
    assert(!User.exists?(user_id))
  end

  # for page status test
  def test_page_status
    # editing to publish request
    page = Page.new(:name => 'testpage', :title => 'ステータステスト',
                    :genre_id => 1)
    page.save
    content = page.private
    content.content = 'test'
    content.admission = PageContent::EDITING
    content.top_news = nil
    content.section_news = nil
    content.save
    post(:update_private_page_status, :id => content.id,
         :private => {
           :user_name => 'きたがわ',
           :tel => '090',
           :email => 'kida',
           :comment => 'コメント',
           :admission => 1,
           :section_news => 0,
           :top_news => 0,
         },
         :public_term => {:switch => 'off'})
    page = Page.find(page.id)
    assert_equal(1, page.private.admission)
    assert_equal(1, page.contents.size)
    assert_nil(page.public)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    # publish request to public
    post(:update_private_page_status, :id => page.private.id,
         :private => {
           :user_name => 'きたがわ',
           :tel => '090',
           :email => 'kida',
           :comment => 'コメント',
           :admission => 3,
           :section_news => 0,
           :top_news => 0,
         },
         :public_term => {:switch => 'off'})
    page = Page.find(page.id)
    assert_equal(false, page.private_exist?)
    assert_equal(1, page.contents.size)
    assert(page.public_exist?)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    # publish to editing
    post(:update_page, :id => page.id, :content => {:content => 'testtest'})
    page = Page.find(page.id)
    assert(page.private_exist?)
    assert_equal(2, page.contents.size)
    assert(page.public_exist?)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    # editing (set public_term) to publish request
    begin_date = Time.now + 1
    end_date = Time.now + 86400
    post(:update_private_page_status, :id => page.private.id,
         :private => {
           :user_name => 'きたがわ',
           :tel => '090',
           :email => 'kida',
           :comment => 'コメント',
           'begin_date(1i)' => begin_date.year,
           'begin_date(2i)' => begin_date.month,
           'begin_date(3i)' => begin_date.day.to_i - 1,
           'begin_date(4i)' => begin_date.hour,
           'begin_date(5i)' => begin_date.min,
           'end_date(1i)' => end_date.year,
           'end_date(2i)' => end_date.month,
           'end_date(3i)' => end_date.day,
           'end_date(4i)' => end_date.hour,
           'end_date(5i)' => end_date.min,
           :admission => 1,
           :section_news => 0,
           :top_news => 0,
         },
         :public_term => {:switch => 'on', :end_date_enable => 'on'})
    page = Page.find(page.id)
    assert(page.private_exist?)
    assert_equal(2, page.contents.size)
    assert(page.public_exist?)
    assert_equal("Sun Mar 12 00:00:00 +0900 2006", page.private.begin_date.to_s)
    assert_equal("Tue Mar 14 00:00:00 +0900 2006", page.private.end_date.to_s)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    # publish request (set public_term) to publish
    sleep(1)
    post(:update_private_page_status, :id => page.private.id,
         :private => {
           :user_name => 'きたがわ',
           :tel => '090',
           :email => 'kida',
           :comment => 'コメント2',
           :admission => 3,
           :section_news => 0,
           :top_news => 0,
         },
         :public_term => {:switch => 'off'})
    page = Page.find(page.id)
    assert_equal(false, page.private_exist?)
    assert_equal(2, page.contents.size)
    assert(page.public_exist?)
    assert(!page.public.begin_date)
    assert(!page.public.end_date)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    # publish to editing
    post(:update_page, :id => page.id, :content => {:content => 'testtest'})
    page = Page.find(page.id)
    assert(page.private_exist?)
    assert_equal(3, page.contents.size)
    assert(page.public_exist?)
    assert(!page.private.begin_date)
    assert(!page.private.end_date)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    # editing (set top_news & section_news) to publish request
    post(:update_private_page_status, :id => page.private.id,
         :private => {
           :user_name => 'きたがわ',
           :tel => '090',
           :email => 'kida',
           :comment => 'コメント3',
           :admission => 1,
           :section_news => 1,
           :top_news => 1,
         },
         :public_term => {:switch => 'off', :end_date_enable => 'off'})
    page = Page.find(page.id)
    assert(page.private_exist?)
    assert_equal(3, page.contents.size)
    assert(page.public_exist?)
    assert(!page.private.begin_date)
    assert(!page.private.end_date)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    # publish request (set top_news & section_news) to publish
    sleep(1)
    post(:update_private_page_status, :id => page.private.id,
         :private => {
           :user_name => 'きたがわ',
           :tel => '090',
           :email => 'kida',
           :comment => 'コメント4',
           :admission => 3,
           :section_news => 0,
           :top_news => 0,
         },
         :public_term => {:switch => 'off'})
    page = Page.find(page.id)
    assert_equal(false, page.private_exist?)
    assert_equal(3, page.contents.size)
    assert(page.public_exist?)
    assert(!page.public.begin_date)
    assert(!page.public.end_date)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    # publish to publish CANCEL
    page_content = page.public_page
    now = Time.now
    post(:update_public_page_status, :id => page_content.id,
         :public => {
           :user_name => 'きたがわ',
           :tel => '090',
           :email => 'kida',
           :comment => 'コメント5',
           :admission => 4,
           :section_news => 0,
           :top_news => 0,
           'last_modified(1i)' => now.year,
           'last_modified(2i)' => now.month,
           'last_modified(3i)' => now.day,
           'last_modified(4i)' => now.hour,
           'last_modified(5i)' => now.min,
         },
         :public_term => {:switch => 'off'})
    page = Page.find(page.id)
    assert_equal(false, page.private_exist?)
    assert_equal(3, page.contents.size)
    assert(page.public_exist?)
    assert(!page.public.begin_date)
    assert(!page.public.end_date)
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
  end

  def test_edit_title
    page = Page.find(1)
    get(:edit_title, :id => 1)
    assert_equal(page, assigns(:page))
  end

  def test_update_title_success
    page = Page.find(1)
    post(:update_title, :id => 1, :page => {:title => 'テストです'})
    assert_redirected_to(:action => 'show_page_info', :id => page.id)
    assert_equal('テストです', assigns(:page).title)
  end

  def test_update_title_failure
    page = Page.find(1)
    post(:update_title, :id => 1, :page => {:title => ''})
    assert_response(:success)
    assert_template('edit_title')
    assert_equal('', assigns(:page).title)
  end

  def test_move_page_with_end_date
    page = Page.find(3)
    Job.create(:action => 'remove_attachment',
               :arg1 => "#{page.path_base}.data/test.pdf",
               :datetime => Time.now + 60*60*24*3650) 
    post(:update_private_page_status,
         :public_term => {:switch => "on", "end_date_enable"=>"on"},
         "private"=>{
           :email => "noreply",
           "begin_date(1i)"=>"2006",
           "begin_date(2i)"=>"4",
           "begin_date(3i)"=>"4",
           "begin_date(4i)"=>"11",
           "begin_date(5i)"=>"00",
           "end_date(1i)"=>"2006",
           "end_date(2i)"=>"4",
           "end_date(3i)"=>"8",
           "end_date(4i)"=>"11",
           "end_date(5i)"=>"00",
           :section_news => PageContent::NEWS_YES,
           :section_news => PageContent::NEWS_YES,
           :admission => PageContent::PUBLISH
         },
         :id => page.contents[0].id
         )
    assert_response(:redirect)
    page.reload
    assert_equal(PageContent::PUBLISH, page.public.admission)
    job1, job2, job3 = Job.find(:all, :order => 'id desc', :limit => 3)
    assert_equal('enable_remove_attachment', job1.action)
    assert_equal('/genre1/genre2/page2.data/', job1.arg1)
    assert_nil(job1.arg2)
    assert_equal('create_page', job3.action)
    assert_equal('3', job3.arg1)
    assert_nil(job3.arg2)
    assert_equal('cancel_page', job2.action)
    assert_equal('3', job2.arg1)
    assert_nil(job2.arg2)
    now = Time.now
    post(:update_public_page_status,
         :public => {
           :admission => PageContent::CANCEL,
           :comment => 'another comment',
           'last_modified(1i)' => now.year,
           'last_modified(2i)' => now.month,
           'last_modified(3i)' => now.day,
           'last_modified(4i)' => now.hour,
           'last_modified(5i)' => now.min,
         },
         :id => Page.find(3).contents[0].id)
    assert_response(:redirect)
    page = Page.find(3)
    assert_equal(PageContent::CANCEL, page.public.admission)
    assert_equal('another comment', page.public.comment)
    job = Job.find(:first, :order => 'id desc')
    assert_equal('cancel_page', job.action)
    assert_equal('3', job.arg1)
    assert_nil(job.arg2)
  end

  def test_search_genre
    xhr(:post, :search_genre, :uri => 'http://example.com/uri/')
    assert_response(:success)
    assert_template('_search_genre')
    assert_equal(3, assigns(:genres).size)
  end

  def test_import_all
    get(:import_all, :id => 1)
    assert_equal(Genre.find(1), assigns(:genre))
  end

  def test_upload_import_zip
    genre_id = 2
    section_id = 234
    path = "#{Page::ZIP_FILE_PATH}/#{section_id}"
    log = system("zip #{RAILS_ROOT}/tmp/config.zip #{RAILS_ROOT}/public/config.html")
    post(:upload_import_zip, :id => genre_id, :file => {:content => uploaded_file("#{RAILS_ROOT}/tmp/config.zip", 'text/plain', 'config.zip')})
    assert_response(:redirect)
    assert(File.exist?("#{path}/config.zip"))
    assert(File.exist?("#{path}/genre_id"))
    system("rm -r #{path}/*")
  end

  def test_page_link_check
    get(:page_link_check)
    assert_response(:success)
    assert_template('page_link_check')
  end

  def test_remove_lost_link
    get(:remove_lost_link, :id => 1)
    assert_response(:redirect)
    assert_redirected_to(:action => 'page_link_check')
  end

  def test_store_enquete_items
    EnqueteItem.destroy_all
    page_content = page_contents(:enquete_test_page_public)
    post(:update_private_page_status,
         :public_term => {:switch => "off"},
         :private => {
           :comment => 'some comment',
           :email => 'noreply',
           :section_news => PageContent::NEWS_YES,
           :admission => PageContent::PUBLISH},
         :id => page_content.id
         )
    assert_response(:redirect)
    enquete_items = EnqueteItem.find(:all, :order => 'no')
    assert_equal 6, enquete_items.size
    assert_equal 0, enquete_items[0].no
    assert_equal 'check', enquete_items[0].form_type
    assert_equal '質問1', enquete_items[0].name
    assert_equal ['A','B'], enquete_items[0].enquete_item_values.map{|v|v.value}.sort
    assert_equal 1, enquete_items[1].no
    assert_equal 'check_other', enquete_items[1].form_type
    assert_equal '質問2', enquete_items[1].name
    assert_equal ['A','B'], enquete_items[1].enquete_item_values.map{|v|v.value}.sort
    assert_equal 4, enquete_items[4].no
    assert_equal 'text', enquete_items[4].form_type
    assert_equal '質問5', enquete_items[4].name
    assert enquete_items[4].enquete_item_values.blank?
  end

  private

  def uploaded_file(path, content_type = 'application/octet-stream', filename = File.basename(path))
    t = Tempfile.new(filename);
    FileUtils.copy_file(path, t.path)
    (class << t; self; end).class_eval do
      alias local_path path
      define_method(:original_filename) {filename}
      define_method(:content_type) {content_type}
    end
    return t
  end

end
