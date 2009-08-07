require File.dirname(__FILE__) + '/../test_helper'

class PageContentTest < Test::Unit::TestCase
  fixtures :page_contents, :pages, :page_links

  def setup
    Time.redefine_now(Time.mktime(2006, 3, 13))
  end

  def teardown
    Time.revert_now
  end

  def _test_relation
    pc = PageContent.find(1).page
    assert_equal('test', pc.page.name)
  end

  def test_before_save
    page = Page.create(:name => 'test11', :genre_id => 1)
    page.contents << PageContent.create(:page_id => page.id)
    pc = page.contents[0]
#    assert_kind_of(Time, pc.last_modified)
  end

  def test_normalize_links
    page_content = PageContent.find(4)
    page_content.save
    page_content.normalize_links
    assert_equal("<a href=\"http://example.com/outer_uri.pdf\">external</a> <a href=\"/full_uri.pdf\">internal full</a> <a href=\"/absolute_uri.pdf\">internal absolute</a> <a href=\"/genre1/genre2/relative_uri.pdf\">internal relative</a> <img src=\"http://example.com/outer_uri.png\" alt=\"test1\" /> <img src=\"/full_uri.png\" alt=\"test2\" /> <img src=\"/absolute_uri.png\" alt=\"test3\" /> <img src=\"/genre1/genre2/relative_uri.png\" alt=\"test4\" />", page_content.content)
    page_content.content = %q|<a href="/full/index.html">index</a><a href="./relative/index.html">index</a><a href="/full/non_index.html">non_index</a><a href="./relative/non_index.html">non_index</a>|
    page_content.normalize_links
    assert_equal(%q|<a href="/full/">index</a><a href="/genre1/genre2/relative/">index</a><a href="/full/non_index.html">non_index</a><a href="/genre1/genre2/relative/non_index.html">non_index</a>|, page_content.content)
  end

  def test_replace_links
    page_content = PageContent.find(4)
    page_content.save
    page_content.replace_links('/full_uri.png', '/full_uri2.png')
    assert_equal("<a href=\"http://example.com/outer_uri.pdf\">external</a> <a href=\"/full_uri.pdf\">internal full</a> <a href=\"/absolute_uri.pdf\">internal absolute</a> <a href=\"/genre1/genre2/relative_uri.pdf\">internal relative</a> <img src=\"http://example.com/outer_uri.png\" alt=\"test1\" /> <img src=\"/full_uri2.png\" alt=\"test2\" /> <img src=\"/absolute_uri.png\" alt=\"test3\" /> <img src=\"/genre1/genre2/relative_uri.png\" alt=\"test4\" />", page_content.content)
  end

  def test_date
    page_content = PageContent.find(1)
    assert_equal(Time.local(2006,1,5,10,0,0), page_content.date)
    page_content.begin_date = Time.local(2006,1,3)
    assert_equal(Time.local(2006,1,3,0,0,0), page_content.date)
    page_content.begin_date = Time.local(2006,1,9)
    assert_equal(Time.local(2006,1,9), page_content.date)
  end

  def test_anchor
    page = PageContent.new(:page_id => 1,
                           :content => %Q!<a href="http://example.com/outer_uri.html">external</a>
<a href="http://#{CMSConfig[:local_domains][0]}/foo.html">external</a>
<a href="http://#{CMSConfig[:local_domains][1]}/foo.html">external</a>
<a href="http://#{CMSConfig[:local_domains][2]}/foo.html">external</a>
<a href="http://www.pref.shimane.jp/foo.html">external</a>
<a href="http://www2.pref.shimane.jp/foo.html">external</a>
<a href="/foo/news.html">absolute</a>
<a href="./news.html">relative1</a>
<a href="/news.html">relative1</a>
<a href="http://example.com/outer_uri.html#foo">external</a>
<a href="/foo/news.html#foo">absolute</a>
<a href="./news.html#foo">relative1</a>
<a href="/news.html#foo">relative1</a>
<a href="/#foo">relative1</a>
<a href="./#foo">relative1</a>
<a href="#foo">relative1</a>!)
    page.save
    assert_equal(%Q!<a href="http://example.com/outer_uri.html">external</a>
<a href="/foo.html">external</a>
<a href="/foo.html">external</a>
<a href="/foo.html">external</a>
<a href="http://www.pref.shimane.jp/foo.html">external</a>
<a href="http://www2.pref.shimane.jp/foo.html">external</a>
<a href="/foo/news.html">absolute</a>
<a href="/genre1/news.html">relative1</a>
<a href="/news.html">relative1</a>
<a href="http://example.com/outer_uri.html#foo">external</a>
<a href="/foo/news.html#foo">absolute</a>
<a href="/genre1/news.html#foo">relative1</a>
<a href="/news.html#foo">relative1</a>
<a href="/#foo">relative1</a>
<a href="/genre1/#foo">relative1</a>
<a href="#foo">relative1</a>!.gsub(/\n/, ''), page.content.gsub(/\n/, ''))
  end

  def test_missing_internal_links
    page = PageContent.new(:page_id => 1,
                           :content => %Q!<a href="http://example.com/outer_uri.html">external</a>
<a href="http://#{CMSConfig[:local_domains][0]}/foo.html">external</a>
<a href="http://#{CMSConfig[:local_domains][1]}/foo.html">external</a>
<a href="http://#{CMSConfig[:local_domains][2]}/foo.html">external</a>
<a href="http://www.pref.shimane.jp/foo.html">external</a>
<a href="http://www2.pref.shimane.jp/foo.html">external</a>
<a href="/foo/news.html">absolute</a>
<a href="./news.html">relative1</a>
<a href="/news.html">relative1</a>
<a href="/genre1/genre2/page1.html">relative1</a>
<a href="http://example.com/outer_uri.html">external</a>
<a href="/foo/news.html">absolute</a>
<a href="./news.html">relative1</a>
<a href="/news.html">relative1</a>!)
    page.save
    warn, err = page.missing_internal_links
    assert_equal(['/genre1/genre2/page1.html'], warn)
    assert_equal(['/foo.html', '/foo/news.html', '/genre1/news.html', '/news.html'], err)
  end

  def test_enquete_items
    enquete_items = page_contents(:enquete_test_page_public).enquete_items
    result = [{:type => 'check',
               :name => "質問1",
               :values => ['A','B']},
              {:type => 'check_other',
               :name => "質問2",
               :values => ['A','B']},
              {:type => 'radio',
               :name => "質問3",
               :values => ['A','B']},
              {:type => 'radio_other',
               :name => "質問4",
               :values => ['A','B']},
              {:type => 'text',
               :name => "質問5",
               :values => nil},
              {:type => 'textarea',
               :name => "質問6",
               :values => nil}]

    assert_equal(result, enquete_items)
  end

  def test_links
    assert_equal(6, page_contents(:link_test_page_public).links.size)
  end

  def test_replace_plugin
    pc = pages(:genre1_2_page1).private
    pc.content = %Q!<p>&nbsp;&lt;%= plugin(&#39;test&#39;) %&gt;</p>!
    assert(pc.save)
    assert_equal("<%= plugin('test') %>", pc.content)
    pc.content = %Q!<p class="test">&nbsp;&lt;%= plugin(&#39;test&#39;) %&gt;</p>!
    assert(pc.save)
    assert_equal("<%= plugin('test') %>", pc.content)
  end

  def test_restore_empty_tag
    ary = [
           ["",""],
           ["<br />","<br />"],
           ["<hr width=\"20\" />","<hr width=\"20\" />"],
           [%Q!<img src="./test.jpg" />!,
            %Q!<img src="./test.jpg" />!],
           [%Q!<input type="text" name="$" />!,
            %Q!<input type="text" name="$" />!],
           [%Q!<a href="/kochokoho" />!,
            %Q!<a href="/kochokoho"></a>!],
    ]
    ary.each do |input, output|
      page_content = PageContent.new(:content => input)
      assert_equal(output, page_content.restore_empty_tag(input))
    end
  end

  def test_cleanup_html
    ary = [
           ["",""],
           [%Q!<p align="left">foo<img src="./test.jpg" align="left"></p>!,
            %r!<p class="left">foo<img src="./test.jpg" class="left" /></p>!],
           [%Q!<p align="center">foo<img src="./test.jpg" align="center"></p>!,
            %r!<p class="center">foo<img src="./test.jpg" class="center" /></p>!],
           [%Q!<p align="right">foo<img src="./test.jpg" align="right"></p>!,
            %r!<p class="right">foo<img src="./test.jpg" class="right" /></p>!],
           [%Q!<div align="left">foo</div>!,
            %r!<div class="left">foo</div>!],
           [%Q!<div align="center">foo</div>!,
            %r!<div class="center">foo</div>!],
           [%Q!<div align="right">foo</div>!,
            %r!<div class="right">foo</div>!],
           [%Q!<table align="left"><tr><th valign="top" align="left">A</th></tr><tr valign="top" align="left"><td><table><tr><td><p>test</p></td></tr></table><table><tr><td><p>bbb</p></td></tr></table></td></tr><table><tr><td>abc</td></tr></table></table>!,
           %r!<div class="table_div_left"><table class="table_left"><tr><th (?:style="vertical-align: top" class="left"|class="left" style="vertical-align: top")>A</th></tr><tr (?:style="vertical-align: top" class="left"|class="left" style="vertical-align: top")><td><table><tr><td><p>test</p></td></tr></table><table><tr><td><p>bbb</p></td></tr></table></td></tr><table><tr><td>abc</td></tr></table></table></div>!],
           [%Q!<table align="left"><tr><th valign="top" align="left">A</th></tr><tr valign="top" align="left"><td><table><tr><td><p>test</p></td></tr></table></td></tr></table>!,
           %r!<div class="table_div_left"><table class="table_left"><tr><th (?:style="vertical-align: top" class="left"|class="left" style="vertical-align: top")>A</th></tr><tr (?:style="vertical-align: top" class="left"|class="left" style="vertical-align: top")><td><table><tr><td><p>test</p></td></tr></table></td></tr></table></div>!],
           [%Q!<table align="left"><tr><th valign="top" align="left">A</th></tr><tr valign="top" align="left"><td valign="top" align="left">A</td></tr></table>!,
           %r!<div class="table_div_left"><table class="table_left"><tr><th (?:style="vertical-align: top" class="left"|class="left" style="vertical-align: top")>A</th></tr><tr (?:style="vertical-align: top" class="left"|class="left" style="vertical-align: top")><td (?:style="vertical-align: top" class="left"|class="left" style="vertical-align: top")>A</td></tr></table></div>!],
           [%Q!<table align="center"><tr><th valign="center" align="center">B</th></tr><tr valign="center" align="center"><td valign="center" align="center">B</td></tr></table>!,
            %r!<div class="table_div_center"><table class="table_center"><tr><th (?:style="vertical-align: center" class="center"|class="center" style="vertical-align: center")>B</th></tr><tr (?:style="vertical-align: center" class="center"|class="center" style="vertical-align: center")><td (?:style="vertical-align: center" class="center"|class="center" style="vertical-align: center")>B</td></tr></table></div>!],
           [%Q!<table align="right"><tr><th valign="bottom" align="right">C</th></tr><tr valign="bottom" align="right"><td valign="bottom" align="right">C</td></tr></table>!,
           %r!<div class="table_div_right"><table class="table_right"><tr><th (?:style="vertical-align: bottom" class="right"|class="right" style="vertical-align: bottom")>C</th></tr><tr (?:style="vertical-align: bottom" class="right"|class="right" style="vertical-align: bottom")><td (?:style="vertical-align: bottom" class="right"|class="right" style="vertical-align: bottom")>C</td></tr></table></div>!],
           [%Q!<p class="foo">\n<table cellspacing="0"><tr><td>1</td></tr></table>\n</p>!,
           %r!<div class="foo"><table cellspacing="0"><tr><td>1</td></tr></table></div>!],
         ]
    ary.each do |input, output|
      page_content = PageContent.new(:content => input)
      page_content.cleanup_html
      assert_match(output, page_content.content.gsub(/\n/, ''))
    end
  end

  def test_publish_normal
    # normal case
    page = Page.find(30)
    page_content = page.contents[0]
    page_content.update_attributes(:begin_date => Time.now + 2,
                                   :end_date => Time.now + 3,
                                   :admission => PageContent::PUBLISH)
    page_content.publish
    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    assert_equal(1, create_jobs.size)
    assert_equal(page_content.begin_date, create_jobs[0].datetime)
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(1, cancel_jobs.size)
    assert_equal(page_content.end_date, cancel_jobs[0].datetime)
  end

  def test_publish_with_jobs
    # when there are preceding jobs and waiting_page.
    page = Page.find(30)
    page_content = page.contents[0]
    page_content.update_attributes(:begin_date => Time.now + 2,
                                   :end_date => Time.now + 3,
                                   :admission => PageContent::PUBLISH)
    waiting_page = page.private
    waiting_page.update_attributes(:begin_date => Time.now + 4,
                                   :end_date => Time.now + 5,
                                   :admission => PageContent::PUBLISH)
    waiting_page.publish
    # An old create job
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => Time.now - 1)
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => Time.now)
    Job.create(:action => 'create_page', :arg1 => page.id,
               :datetime => Time.now + 1)
    # A cancel job whose datetime is greater than newer begin_date.
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page_content.begin_date + 1)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page_content.begin_date)
    Job.create(:action => 'cancel_page', :arg1 => page.id,
               :datetime => page_content.begin_date - 1)
    page_content.publish

    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    assert_equal(3, create_jobs.size)
    assert_equal(page_content.begin_date, create_jobs[0].datetime)
    assert_equal(Time.now + 1, create_jobs[1].datetime)
    assert_equal(waiting_page.begin_date, create_jobs[2].datetime)
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(3, cancel_jobs.size)
    assert_equal(page_content.end_date, cancel_jobs[0].datetime)
    assert_equal(page_content.begin_date - 1, cancel_jobs[1].datetime)
    assert_equal(waiting_page.end_date, cancel_jobs[2].datetime)

    # with waiting_page without end_date.
    Job.destroy_all
    waiting_page.update_attributes(:begin_date => Time.now + 4,
                                   :end_date => nil,
                                   :admission => PageContent::PUBLISH)
    waiting_page.publish
    page_content.publish

    create_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'create_page', page.id],
                           :order => 'id desc')
    assert_equal(2, create_jobs.size)
    assert_equal(page_content.begin_date, create_jobs[0].datetime)
    assert_equal(waiting_page.begin_date, create_jobs[1].datetime)
    cancel_jobs = Job.find(:all, :conditions => ['action = ? AND arg1 = ?',
                                                 'cancel_page', page.id],
                           :order => 'id desc')
    assert_equal(1, cancel_jobs.size)
    assert_equal(page_content.end_date, cancel_jobs[0].datetime)
  end
end
