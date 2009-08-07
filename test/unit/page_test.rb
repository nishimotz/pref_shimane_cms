require File.dirname(__FILE__) + '/../test_helper'
require 'nkf'

class PageTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "iso-2022-jp"

  fixtures :pages, :genres, :page_contents, :page_links, :users

  include ActionMailer::Quoting

  def setup
    Time.redefine_now(Time.mktime(2006, 2, 2))
    @emails     = ActionMailer::Base.deliveries
    @emails.clear

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def teardown
    Time.revert_now
  end

  def test_relation
    p_page = Page.find(1).public
    assert(p_page)
    p_page = Page.find(1).private
    assert( p_page)
  end

  def test_validate_name
    page = Page.find(1)
    duplicate_page = Page.create(:name => page.name,
                        :title => 'test title',
                        :genre_id => page.genre_id)
    assert_equal(1, duplicate_page.errors.count)
    assert_equal('そのページ名はすでに使われています', duplicate_page.errors[:name])
    non_duplicate_page = Page.create(:name => 'test1',
                                     :title => 'test title',
                                     :genre_id => 2)
    assert_equal(0, non_duplicate_page.errors.count)
    duplicate_page = Page.create(:name => 'test1',
                                 :title => 'test title2',
                                 :genre_id => non_duplicate_page.genre_id)
    assert_equal(1, duplicate_page.errors.count)
    assert_equal('そのページ名はすでに使われています', duplicate_page.errors[:name])
  end

  def test_validate_title
    page = Page.find(1)
    new_page = Page.create(:name => 'test_validate_page',
                        :title => page.title,
                        :genre_id => page.genre_id)
    assert_equal(1, new_page.errors.count)
    assert_equal('そのタイトルはすでに使われています', new_page.errors[:title])
  end

  def _test_images
    page = Page.find(3)
    assert_equal(4, page.images.size)
    assert_equal(3, page.local_images.size)
  end

  def test_path
    assert_equal('/genre1/', pages(:genre1_index).path)
  end

  def test_public_enable?
    page = Page.find(30)
    assert_equal(false, page.public_enable?)
    content = page.private
    content.admission = 3
    content.last_modified = Time.now
    content.begin_date = Time.now
    content.end_date = nil
    content.save
    sleep(1)
    page = Page.find(30)
    page.public.begin_date = Time.now - 86400
    page.public.end_date = Time.now + 86400
    page.save
    assert_equal(true, page.public_enable?)
  end

  def test_current
    page = Page.find(30)
    assert_nil(page.current)
    assert_kind_of(PageContent, page.public)
  end

  def test_public_page
    page = Page.find(30)
    # 公開期間を指定しない(有効)
    content = page.private
    content.begin_date = nil
    content.end_date = nil
    content.admission = 3
    content.save
    # 公開期間で開始日だけ指定(有効)
    content = page.private
    content.begin_date = Time.local(2006, 1, 2)
    content.end_date = nil
    content.admission = 3
    content.save
    # 公開期間で開始日、終了日を指定(有効)
    content = page.private
    content.begin_date = Time.local(2006, 1, 3)
    content.end_date = Time.local(2006, 2, 3)
    content.admission = 3
    content.save
    page = Page.find(30)
    assert_equal(Time.local(2006, 1, 3), page.public_page.begin_date)
    # 公開期間で開始日、終了日を指定(無効)
    content = page.private
    content.begin_date = Time.local(2006, 2, 4)
    content.end_date = Time.local(2006, 2, 6)
    content.admission = 3
    content.save
    page = Page.find(30)
    assert_equal(Time.local(2006, 1, 3), page.public_page.begin_date)
    # CANCEL(無効)
    content = page.private
    content.begin_date = Time.local(2006, 2, 4)
    content.end_date = Time.local(2006, 2, 6)
    content.admission = 4
    content.save
    page = Page.find(30)
    assert_equal(Time.local(2006, 1, 3), page.public_page.begin_date)
    # 日付無し(有効)
    content = page.private
    content.begin_date = nil
    content.end_date = nil
    content.admission = 3
    content.save
    page = Page.find(30)
    assert_equal(nil, page.public_page.begin_date)
    # 公開期限切れ(無効)
    content = page.private
    content.begin_date = Time.local(2006, 1, 2)
    content.end_date = Time.local(2006, 2, 1)
    content.admission = 3
    content.save
    page = Page.find(30)
    assert_equal(Time.local(2006, 1, 2), page.public_page.begin_date)
    # 公開待ち(無効)
    content = page.private
    content.begin_date = Time.local(2006, 2, 10)
    content.end_date = Time.local(2006, 2, 22)
    content.admission = 3
    content.save
    page = Page.find(30)
    assert_equal(Time.local(2006, 1, 2), page.public_page.begin_date)
  end

  def test_private_page
    page = Page.find(30)
    # 編集ページ作成
    content = page.private
    content.begin_date = nil
    content.end_date = nil
    content.admission = 0
    content.save
    page = Page.find(30)
    assert_equal(0, page.private_page.admission)
    # 公開依頼
    content = page.private
    content.begin_date = nil
    content.end_date = nil
    content.admission = 1
    content.save
    page = Page.find(30)
    assert_equal(1, page.private_page.admission)
    # 却下
    content = page.private
    content.begin_date = nil
    content.end_date = nil
    content.admission = 2
    content.save
    page = Page.find(30)
    assert_equal(2, page.private_page.admission)
    # 公開
    content = page.private
    content.begin_date = nil
    content.end_date = nil
    content.admission = 3
    content.save
    page = Page.find(30)
    assert_equal(nil, page.private_page)
    # 編集ページ作成
    content = page.private
    content.begin_date = nil
    content.end_date = nil
    content.admission = 0
    content.save
    page = Page.find(30)
    assert_equal(0, page.private_page.admission)
    # 公開待ち
    content = page.private
    content.begin_date = Time.local(2006, 2, 5)
    content.end_date = Time.local(2006, 2, 9)
    content.admission = 3
    content.save
    page = Page.find(30)
    assert_equal(3, page.private_page.admission)
  end

  def test_private_exist
    page = Page.find(30)
    assert !page.private_exist?
    content = page.private
    content.admission = 0
    content.save
    page.reload
    assert page.private_exist?
    content.admission = 1
    content.save
    page.reload
    assert page.private_exist?
    content.admission = 2
    content.save
    page.reload
    assert page.private_exist?
    content.admission = 3
    content.save
    page.reload
    assert !page.private_exist?
    content.admission = 4
    content.save
    page.reload
    assert !page.private_exist?
  end

  def test_find_by_path
    assert_equal('/genre1/genre2/page1.html',
                 Page.find_by_path('/genre1/genre2/page1.html').path)
    assert_equal('/genre1/',
                 Page.find_by_path('/genre1/').path)
    assert_equal('/genre1/',
                 Page.find_by_path('/genre1/index.html').path)
  end

  def test_destroyable
    page = Page.new(:name => 'destroy_test_failure',
                    :title => 'ページ削除のテスト',
                    :genre_id => 53)
    page.contents << PageContent.new(:content => 'なし',
                                     :admission => PageContent::PUBLISH_REQUEST
                                     )
    user = users(:normal_user)
    assert_equal(false, page.destroyable?(user))
    section_manager = users(:section_manager)
    assert(page.destroyable?(section_manager))
    super_user = users(:super_user)
    assert(page.destroyable?(super_user))
  end

  def test_genres
    page = Page.find(1)
    assert_equal([Genre.find(1), Genre.find(2)], page.genres)
  end

  def test_add_revision
    page = Page.find(1)
    page.add_revision(PageRevision.new(:last_modified => Time.now,
                                       :user_id => 1))
    assert_equal(3, page.revisions.size)
  end

  def test_section_manager
    page = Page.find(1)
    assert_equal(users(:section_manager), page.section_manager)
  end

  def test_send_enquete_update_mail
    page = Page.find(1)
    page.send_enquete_update_mail
    assert_equal(1, @emails.size)
    email = @emails.first
    @expected.subject = NKF.nkf('-EjM', NKF.nkf('-We', "CMS : アンケート受信のお知らせ" ))
    @expected.body    = read_fixture('enquete_answer_exist')
    @expected.date    = Time.now
    @expected.from    = CMSConfig[:super_user_mail]
    @expected.to      = users(:section_manager).mail
    assert_equal(NKF::nkf('-jm0', @expected.encoded), email.encoded)
  end

  def test_top_news
    genre = genres(:genre1)
    top_news = genre.all_pages.select{|page| page.current }.each do |page|
      page.current.update_attributes(:top_news => PageContent::NEWS_YES,
                                     :begin_date => Time.now - 10*60*60*24 + 1)
    end

    args = []
    news = Page.top_news(args)
    assert_equal(2, news.size)
    genre = genres(:genre1)
    news = Page.top_news(args, genre)
    assert_equal(2, news.size)
    genre = genres(:genre2)
    news = Page.top_news(args, genre)
    assert_equal(0, news.size)

    args = [10]
    genre = genres(:genre1)
    news = Page.top_news(args, genre)
    assert_equal(2, news.size)
    args = [10, 10]
    news = Page.top_news(args, genre)
    assert_equal(2, news.size)

    top_news.first.current.update_attributes(:top_news => PageContent::NEWS_YES,
                                     :begin_date => Time.now - 10*60*60*24 - 1)
    news = Page.top_news(args, genre)
    assert_equal(1, news.size)
    top_news.last.current.update_attributes(:top_news => PageContent::NEWS_YES,
                                     :begin_date => Time.now - 10*60*60*24 - 1)
    news = Page.top_news(args, genre)
    assert_equal(0, news.size)
  end
  
  def enable_top_news(page_content)
    page_content.update_attribute(:top_news, PageContent::NEWS_YES)
  end
  
  def disable_top_news(page_content)
    page_content.update_attribute(:top_news, PageContent::NEWS_NO)
  end

  def test_genre_news
    args = []
    list = Page.genre_news(args, Genre.find(2))
    assert_equal(1, list.size)
  end

  def test_section_news
    args = []
    list = Page.section_news(Genre.find(3))
    assert_equal(1, list.size)
  end

  def test_destroy_files
    page_id = 1
    dir_path = "#{AdminController::FILE_PATH}/#{page_id}"
    file_path = File.join(dir_path, "#{page_id}.png") 
    FileUtils.mkdir(dir_path)
    FileUtils.copy_file("#{RAILS_ROOT}/tmp/test.png", file_path)
    assert(File.exist?(file_path))
    Page.find(1).destroy
    assert(!File.exist?(file_path))
  end

  # Test for news_title method.
  def test_news_title
    page = pages(:news_title)

    # if content news_title is nil, show page.title
    assert('新着見出しのテストページ', page.news_title)

    # if content news_title is empty, show page.title
    page.public.update_attribute(:news_title, '')
    assert('新着見出しのテストページ', page.news_title)

    # if content news_title exist, show it
    page.public.update_attribute(:news_title, 'new news_title')
    assert('new news_title', page.news_title)
  end

  private

  def read_fixture(action)
    ERB.new(File.read("#{FIXTURES_PATH}/notify_mailer/#{action}")).result
  end

  def encode(subject)
    quoted_printable(subject, CHARSET)
  end
end
