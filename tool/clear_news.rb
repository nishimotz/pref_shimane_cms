#!/usr/bin/env ruby

ENV['RAILS_ENV'] ||= 'production'

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rubi_adder'
require "#{RAILS_ROOT}/tool/gtalk/voice-synthesis/voice_synthesis"
require 'open-uri-override'
require 'fileutils'
require 'htree'

#### Config ####
#  SERVER = ['www1.pref.shimane.lg.jp', 'www2.pref.shimane.lg.jp']
#  USER = 'www-update'

  SERVER = ['localhost']
  USER = 'www-data'

  SYNC_ENABLE_FILE_PATH = '/var/share/cms/do_sync'
################

##############################EXPORT##################################
def create_page_by_path(arg)
  path = arg_to_path(arg)
  flag = create_html(path)
  create_mobile_html(path) # if flag
  rubi_flag = create_rubi_html(path, flag)
  if rubi_flag
    prepare_mp3(arg)
  end
end

def arg_to_path(arg)
  case arg
  when /\Ap:(\d+)\z/
    path = Page.find($1.to_i).path
  when /\Ag:(\d+)\z/
    path = Genre.find($1.to_i).path
  else
    path = arg
  end
  return path
end

def create_html(path)
  html_path = "#{DOCROOT}#{path_html(path)}"
  FileUtils.mkdir_p(File.dirname(html_path))
  html = open(BASE_URI + path) { |f| f.read }
  raise if html.blank?
  old_html = File.read(html_path) rescue nil
  if @counter_regexp =~ html
    page_id = $1.to_i
    num = $2.to_i
    File.open(File.join(@counter_dir, page_id.to_s), 'w') do |f|
      f.puts num
    end
  end
  if html == old_html
    ret = false
  else
    File.open(html_path, 'w') do |f|
      f.print html
    end
    ret = true
  end
  if path_base(path) == '/index' # top page only
    qr_path = path_qr(path)
    qr_file_path = "#{DOCROOT}#{qr_path}"
    unless File.exist?(qr_file_path)
      qr = open(BASE_URI + qr_path) { |f| f.read }
      FileUtils.mkdir_p("#{File.dirname(qr_file_path)}")
      File.open(qr_file_path, 'w') do |f|
        f.print qr
      end
    end
  end
  page = Page.find_by_path(path)
  if page
    data_path_from = "#{RAILS_ROOT}/files/#{ENV['RAILS_ENV']}/#{page.id}/"
    if File.directory?(data_path_from)
      data_path_to = "#{DOCROOT}#{path_data(path)}"
      FileUtils.mkdir_p("#{File.dirname(data_path_to)}")
      system('rsync', '-a', '--delete', data_path_from, data_path_to)
    end
  end
  return ret
end

def create_mobile_html(path, force = true)
  mobile_path = path_mobile(path)
  html = open(BASE_URI + mobile_path) { |f| f.read }
  raise if html.blank?
  File.open("#{DOCROOT}#{mobile_path}", 'w') do |f|
    f.print html
  end
end

def create_rubi_html(path, force = false)
  rubi_path = "#{DOCROOT}#{path_rubi(path)}"
  if !force && File.exist?(rubi_path) && File.mtime(rubi_path) > Word.last_modified
    return false
  end
  old_rubi_html = File.read(rubi_path) rescue ''
  html = File.read("#{DOCROOT}#{path_html(path)}")
  new_rubi_html = RubiAdder.add(html).sub(/\.html\.r"><img alt="ふりがなをつける/, '.html"><img alt="ふりがなをけす').sub(%r!/images/ruby_off.png!, '/images/ruby_on.png')
  modified = (old_rubi_html.slice(/<!-- begin_content -->(.*)<!-- end_content -->/m) != new_rubi_html.slice(/<!-- begin_content -->(.*)<!-- end_content -->/m))
  if modified
    File.open(rubi_path, 'w') do |f|
      f.print new_rubi_html
    end
    FileUtils.rm_f(Dir.glob("#{DOCROOT}#{path_base(path)}.*.md5"))
  else
    FileUtils.touch(rubi_path)
  end
  return modified
end

def prepare_mp3(arg)
  path = arg_to_path(arg)
  m3u_path = "#{DOCROOT}#{path_m3u(path)}"
  rubi_path = "#{DOCROOT}#{path_rubi(path)}"
  if (File.mtime(m3u_path) > File.mtime(rubi_path) rescue nil)
    return
  end
  File.open(m3u_path, 'w') do |f|
    f.puts "#{CMSConfig[:public_uri]}not_found.mp3"
  end
  tmp_id = Time.now.to_f
  tmp_dir = File.expand_path("#{RAILS_ROOT}/tmp/#{tmp_id}/")
  FileUtils.rm_rf(tmp_dir)
  FileUtils.mkdir_p(tmp_dir)
  FileUtils.cp(Dir["#{DOCROOT}#{path_base(path)}.{html.r,m3u,*.mp3,*.md5}"],
               tmp_dir, :preserve => true)
  Job.create(:action => 'create_mp3',
             :arg1 => arg,
             :arg2 => tmp_id,
             :datetime => Time.now)
end

def path_base(path)
  if /(.+)\.html\z/ =~ path
    return $1
  else
    "#{path}index"
  end
end

def path_html(path)
  "#{path_base(path)}.html"
end

def path_rubi(path)
  "#{path_base(path)}.html.r"
end

def path_mobile(path)
  "#{path_base(path)}.html.i"
end

def path_m3u(path)
  "#{path_base(path)}.m3u"
end
##########################################################################

six_month_ago = Time.now - (((60 * 60 * 24) * 31) *  6)
news = News.find(:all, :conditions => ['published_at < ?', six_month_ago])

news.each do |n|
  n.destroy
end

`rm /var/share/cms/public./news.*.html`

(1..News.page_count).each do |i|
  create_page_by_path("/news.#{i}.html")
end

if File.exist?(SYNC_ENABLE_FILE_PATH)
  SERVER.each do |s|
    system("rsync -aLz --delete --exclude='*.md5' --exclude=.svn /var/share/cms/public./ #{USER}@#{s}:/var/www/cms/")
  end
end
