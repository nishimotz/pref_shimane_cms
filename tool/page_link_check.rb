#!/usr/bin/env ruby

ENV['RAILS_ENV'] ||= 'production'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require "htree"
require "webclient/link"
require "uri"
require "net/http"
require "logger"
require "progressbar"
require "nkf"

# CMSページへのリンク切れ一覧抽出
LostLink.destroy_all
Section.find(:all).each do |section|
  section.genres.each do |genre|
    genre.pages.each do |page|
      if page && page.current
        warn, err = page.current.missing_internal_links
        unless warn.empty?
          warn.each do |w|
            LostLink.create(:page_id => page.id, :section_id => section.id,
                            :side_type => LostLink::INSIDE_TYPE,
                            :target => w, :message => LostLink::WARN_MSG)
          end
        end
        unless err.empty?
          err.each do |e|
            LostLink.create(:page_id => page.id, :section_id => section.id,
                            :side_type => LostLink::INSIDE_TYPE,
                            :target => e, :message => LostLink::ERR_MSG)
          end
        end
      end
    end
  end
end

# 外部サイトへのリンク切れ一覧抽出
include WebClient

$logger = Logger.new("#{RAILS_ROOT}/log/link_check.log")
$logger.level = Logger::WARN

def success_uri?(uri, limit = 10)
  @cache ||= {}
  return @cache[uri] if @cache.has_key?(uri)
  if limit == 0
    raise ArgumentError, 'HTTP redirect too deep'
  end
  http = Net::HTTP.new(uri.host, uri.port, CMSConfig[:proxy_addr], CMSConfig[:proxy_port])
  begin
    http.open_timeout = 5
    http.read_timeout = 5
    http.start
    response = http.head(uri.path)
    case response
    when Net::HTTPOK
      @cache[uri] = true
      return true
    when Net::HTTPSuccess
      @cache[uri] = true
      return true
    when Net::HTTPRedirection
      return success_uri?(URI.parse(response['location']), limit - 1)
    end
  rescue TimeoutError
  ensure
    http.finish rescue nil
  end
  @cache[uri] = false
  return false
end

def check_link(filename, base_uri)
  path = filename.sub(%r!\A#{Regexp.quote(BASE_DIR)}/?!, '/')
  page = Page.find_by_path(path)
  return unless page
  errors = []
  $logger.debug("filename=[#{filename}] base_uri=[#{base_uri.to_s}]")
  text = File.read(filename)
  text.sub!(/\A.*?<!-- begin_content -->/m, '')
  text.sub!(/<!-- end_content -->.*?\z/m, '')
  h = HTree.parse("<html><body>#{text}</body></html>")
  Link.extract_all_from(h).each do |link|
    begin
      next if /\A#/ =~ link.href
      $logger.debug("try href=[#{link.href}] text=[#{link.text}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
      uri = base_uri.merge(link.href)
      if /\Ahttps?\z/ !~ uri.scheme
        $logger.debug("skip href=[#{link.href}] text=[#{link.text}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
      elsif %r!\A/! =~ link.href
        file = File.expand_path("#{$base_dir.sub(%r!/*\z!, '/')}#{link.href}")
        file.sub!(%r!#.*\z!, '')
        file.sub!(%r!/\z!, '/index.html')
        if File.readable?(file)
          $logger.info("success_local link=[#{uri.to_s}] href=[#{link.href}] text=[#{link.text}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
        else
          $logger.error("failure_local link=[#{uri.to_s}] href=[#{link.href}] text=[#{link.text}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
#          errors << [link.href, link.text]
        end
      else
        if success_uri?(uri)
          $logger.info("success_remote link=[#{uri.to_s}] href=[#{link.href}] text=[#{link.text}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
        else
          $logger.error("failure_remote link=[#{uri.to_s}] href=[#{link.href}] text=[#{link.text}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
          errors << [link.href, link.text]
        end
      end
    rescue
      unless %r!\A/! =~ link.href
        $logger.fatal("failure_error link=[#{uri.to_s}] href=[#{link.href}] text=[#{link.text}] base_uri=[#{base_uri.to_s}] filename=[#{filename}]")
        errors << [link.href, link.text]
      end
    end
  end
  unless errors.empty?
    msg = ""
    msg += %Q!<ul>!
    errors.each do |href, link_text|
      msg += %Q!<li>#{ERB::Util.h(href)} (#{ERB::Util.h(link_text)})</li>!
    end
    if msg != ""
      LostLink.create(:page_id => page.id, :section_id => page.genre.section.id,
                      :side_type => LostLink::OUTSIDE_TYPE,
                      :target => nil, :message => msg)
    end
  end
  $progress.inc rescue nil
end

def traverse_dir(base_dir, base_uri)
  $logger.debug("base_dir=[#{base_dir}] base_uri=[#{base_uri.to_s}]")
  Dir.glob(File.join(base_dir, "*")) do |path|
    if FileTest.file?(path)
      if /\.html$/ =~ path
        check_link(path, base_uri)
      end
    elsif FileTest.directory?(path)
      traverse_dir(path, base_uri.merge(File.basename(path) + "/"))
    else
      $logger.warn("#{path}: This file is not regular file or directory.\n")
    end
  end
end

def count_files(base_dir, n = 0)
  Dir.glob(File.join(base_dir, "*")) do |path|
    if FileTest.file?(path)
      n += 1
    elsif FileTest.directory?(path)
      n = count_files(path, n)
    end
  end
  return n
end

URL_ROOT = CMSConfig[:public_uri]
BASE_DIR = "#{RAILS_ROOT}/public."
#if ARGV.empty?
#  $stderr.puts "Usage: #{$0} base_dir [base_uri]"
#  exit 1
#end

base_uri = URI.parse(URL_ROOT)
File.open("#{RAILS_ROOT}/app/views/admin/_link_check.rhtml.tmp", 'w') do |$file|
  traverse_dir(BASE_DIR, base_uri)
end
FileUtils.mv("#{RAILS_ROOT}/app/views/admin/_link_check.rhtml.tmp", "#{RAILS_ROOT}/app/views/admin/_link_check.rhtml")
