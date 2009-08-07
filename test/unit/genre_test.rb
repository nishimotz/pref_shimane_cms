require File.dirname(__FILE__) + '/../test_helper'

class GenreTest < Test::Unit::TestCase
  fixtures :genres, :pages, :sections, :page_contents, :web_monitors

  def test_path
    root = genres(:top)
    assert_equal('/', root.path)
    child1 = root.children.create("name" => "child1", "title" => 'hoge')
    assert_equal('/child1/', child1.path)
  end

  def test_acts_as_tree
    root = Genre.create("name" => "root", "title" => "root")
    child1 = root.children.create("name" => "child1", "title" => 'hoge')
    subchild1 = child1.children.create("name" => "subchild1", "title" => 'hoge')
    assert_equal(nil, root.parent)
    assert_equal("root", child1.parent.name)
    assert_equal(1, root.children.size)
    assert_equal(subchild1, root.children.first.children.first)
  end

  def test_create
    root = Genre.create("name" => "root2", "title" => "root1")
    child1 = root.children.create("name" => "child1", "title" => "root2")
    child2 = root.children.create("name" => "child1", "title" => "root3")
    assert_equal("フォルダ名が重複しています", child2.errors.on(:name))

    child1 = root.children.create("name" => "子ディレクトリ")
    assert_equal("URL名が正しくありません。半角英数字で入力してください", child1.errors.on(:name))

    child1 = root.children.create("title" => "", "name" => "子ディレクトリ")
    assert_equal("タイトルが空です。", child1.errors.on(:title))
    assert_equal("URL名が正しくありません。半角英数字で入力してください", child1.errors.on(:name))

    child1 = root.children.create("title" => "てすと", "name" => "javascripts")
    assert_equal("javascripts、images、stylesheets、contents、アンダースコアで始まるURL名は使用出来ません。", child1.errors.on(:name))

    child1 = root.children.create("title" => "てすと", "name" => "stylesheets")
    assert_equal("javascripts、images、stylesheets、contents、アンダースコアで始まるURL名は使用出来ません。", child1.errors.on(:name))

    child1 = root.children.create("title" => "てすと", "name" => "images")
    assert_equal("javascripts、images、stylesheets、contents、アンダースコアで始まるURL名は使用出来ません。", child1.errors.on(:name))

    child1 = root.children.create("title" => "てすと", "name" => "image")
    assert_equal(nil, child1.errors.on(:name))

    child1 = root.children.create("title" => "hoe", "name" => "hjoge")
    assert(child1.errors.empty?)
  end

  def test_self_find_by_name
    genre = genres(:genre1_2)
    assert_equal(genre, Genre.find_by_name(genre.path))
  end

  def test_each_genre
    ary = []
    genres(:top).each_genre{|i| ary << i}
    assert_equal([], ary)
    ary = []
    genres(:genre1).each_genre{|i| ary << i}
    assert_equal([genres(:top)], ary)
    ary = []
    genres(:genre1_2).each_genre{|i| ary << i}
    assert_equal([genres(:top), genres(:genre1)], ary)
  end

  def test_update_path
    genre = Genre.create(:name => 'test', :parent_id => genres(:genre2).id)
    assert_equal('/genre2/test/', genre.path)
    genre.parent_id = genres(:genre3).id
    genre.save
    assert_equal('/genre3/test/', genre.path)
  end

  def test_all_pages
    assert_equal(["/genre1/",
                   "/genre1/genre2/genre3/page1.html",
                   "/genre1/genre2/page1.html",
                   "/genre1/genre2/page2.html"],
                 genres(:genre1).all_pages.collect{|i| i.path}.sort)
  end

  def test_has_current_page 
    assert genres(:genre1).has_current_page?
    assert !genres(:genre2).has_current_page?
  end

  def test_top_news_pages
    genre = genres(:genre1)
    current_pages = genre.all_pages.select{|page| page.current }.sort_by{|page| page.current.date}.reverse
    current_pages.each do |page|
      page.current.update_attribute(:top_news, PageContent::NEWS_YES)
    end
    top_news = genre.top_news_pages
    assert_equal(current_pages, top_news)
  end

  def test_news_page_contents
    genre_news_page_contents = genres(:genre1).news_page_contents
    assert_equal(1, genre_news_page_contents.size)
  end

  def test_link_path
    assert_equal("/enquete/", genres(:enquete).link_path)
    assert_equal("http://example.com/uri/", genres(:with_uri).link_path)
  end

  def test_analytics_code
    code = "<script src=\"http://www.google-analytics.com/urchin.js\" type=\"text/javascript\"> </script> <script type=\"text/javascript\">\n  _uacct = \"UA-1268011-3\";\n   urchinTracker();\n</script>"
    genre = Genre.find(1)
    assert_equal(nil, genre.analytics_code)

    genre = Genre.find(2)
    assert_equal(code, genre.analytics_code)

    genre = Genre.find(3)
    assert_equal(code, genre.analytics_code)
  end

  def test_create_auth_job
    Job.destroy_all("action = 'create_htaccess' OR action = 'destroy_htaccess'")
    genre = genres(:webmonitor)
    web_monitors(:first).update_attribute(:state, WebMonitor::EDITED)

    # Make sure the create_htaccess job is created 
    # when access restriction is enabled.
    genre.update_attribute(:auth, true)
    genre.create_auth_job

    jobs = Job.find_all_by_action('create_htaccess')
    assert_equal 1, jobs.size
    assert_equal genre.id, jobs.first.arg1.to_i
    
    assert genre.web_monitors.all?{|wm| wm.state == WebMonitor::REGISTERED}

    # Make sure the destroy_htacess job is created 
    # when access restriction is disabled.
    genre.update_attribute(:auth, false)
    genre.create_auth_job

    jobs = Job.find_all_by_action('destroy_htaccess')
    assert_equal 1, jobs.size
    assert_equal genre.id, jobs.first.arg1.to_i
  end

  def test_web_monitors_state
    genre = Genre.create("name" => "root", "title" => "root")
    assert !genre.has_edited_monitors?

    genre.web_monitors.create(:name => 'test',
                              :login => 'test_id',
                              :password => 'testtest')
    assert genre.has_edited_monitors?

    genre.web_monitors.create(:name => 'test',
                              :login => 'test_id',
                              :state => WebMonitor::REGISTERED,
                              :password => 'testtest')
    assert genre.has_edited_monitors?

    genre.web_monitors.update_all("state = #{WebMonitor::REGISTERED}")
    genre.reload
    assert !genre.has_edited_monitors?
  end

  def test_destory
    Job.destroy_all
    genre = genres(:webmonitor)
    genre.update_attribute(:auth, true)
    genre_path = genre.path
    genre_id = genre.id

    genre.destroy

    htpasswd_jobs = Job.find_all_by_action('destroy_htpasswd')
    assert_equal 1, htpasswd_jobs.size
    assert_equal genre_id.to_s, htpasswd_jobs.first.arg1

    delete_folder_jobs = Job.find_all_by_action('delete_folder')
    assert_equal 1, delete_folder_jobs.size
    assert_equal genre_path, delete_folder_jobs.first.arg1
  end
end
