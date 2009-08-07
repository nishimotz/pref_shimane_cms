#!/usr/bin/env ruby

ENV['RAILS_ENV'] ||= 'production'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'yaml'
require 'fileutils'

# YAMLSearch
def search_category(id)
  result = ""
  File.open( 'help/help_categories_big.csv' ) do |file|
    lines = file.readlines
    lines.each do |line|
      str = line.chomp.split(/,/)
      result = str[1] if str[0].to_i == id.to_i
    end
  end
  if result.blank? && File.exists?('help/help_categories_middle.csv')
    File.open( 'help/help_categories_middle.csv' ) do |file|
      lines = file.readlines
      lines.each do |line|
        str = line.chomp.split(/,/)
        result = str[1] if str[0].to_i == id.to_i
      end
    end
  end
  if result.blank? && File.exists?('help/help_categories_small.csv')
    File.open( 'help/help_categories_small.csv' ) do |file|
      lines = file.readlines
      lines.each do |line|
        str = line.chomp.split(/,/)
        result = str[1] if str[0].to_i == id.to_i
      end
    end
  end

  category = HelpCategory.find_by_name(result)
  return category.id if category
  return nil
end

def search_content(id, hash)
  result = ""
  hash.each do |key, value|
    old_id = key.gsub(/\"/, '')
    if old_id.to_i == id.to_i
      result = value
      break
    end
  end
  if !result.to_i.zero?
    content = HelpContent.find(result.to_i)
  end
  return content.id if content
  return nil
end

def import(path, type, hash = nil, hash2 = nil)
  content_hash = {}
  File.open(path) do |file|
    lines = file.readlines
    lines.each do |line|
      str = line.chomp.split(/,/)
      case type
      when 'category_big'
        help_category = HelpCategory.new(:name => str[1],
                                         :number => str[3],
                                         :navigation => str[4],
                                         :parent_id => str[2])
        help_category.save
        content_hash.store(str[0], help_category.id)
      when 'content'
        content2 = str[1].gsub(/^\"/, '')
        content = content2.gsub(/\"$/, '')
        content_id = str[0].gsub(/\"/, '')
        help_content = HelpContent.new(:content => content)
        help_content.save
        new_content2 = help_content.content.gsub(%r!"/help_images/([0-9]+)/(.*?)"!, '"/help_images/--replace--/\2"')
        new_content = new_content2.gsub(%r!/help_images/(--replace--)/!, "/help_images/#{help_content.id}/")
        help_content.content = new_content
        help_content.save
        Dir.mkdir("./help_files/#{ENV['RAILS_ENV']}/#{help_content.id}")
        Dir.glob("./help/help_files/#{ENV['RAILS_ENV']}/#{content_id}/*").each do |file|
          file_name = File.basename(file)
          FileUtils.copy("./help/help_files/#{ENV['RAILS_ENV']}/#{content_id}/#{file_name}", "./help_files/#{ENV['RAILS_ENV']}/#{help_content.id}/")
        end
        content_hash.store(str[0], help_content.id)
      when 'help'
        category_id = search_category(str[3])
        content_id = search_content(str[4], hash)
        help = Help.new(:name => str[1],
                        :public => 1,
                        :help_category_id => category_id,
                        :help_content_id => content_id,
                        :number => str[5])
        help.save

        content_hash.store(str[0], help.id)

      when 'action_master'
        master = ActionMaster.new(:name => str[1].gsub(/"/, ""))
        master.save
        content_hash.store(str[0], master.id)
      when 'cms_action'
        cms_action = CmsAction.new(:action_master_id => hash[str[1]].to_i,
                                   :controller_name => str[2],
                                   :action_name => str[3])
        cms_action.save
      when 'help_action'
        if str[3].blank?
          help_category_id = nil
        else
          help_category_id = hash2[str[3]].to_i
        end
        help_action = HelpAction.new(:name => str[1].gsub(/"/, ""),
                                     :action_master_id => hash[str[2]].to_i,
                                     :help_category_id => hash2[str[3]].to_i)
        help_action.save
      else # middle, small category
        if HelpCategory.exists?(hash[str[2]].to_i)
          category = HelpCategory.find(hash[str[2]].to_i)
          help_category = HelpCategory.new(:name => str[1],
                                           :number => str[3],
                                           :navigation => str[4],
                                           :parent_id => category.id)
          help_category.save
          content_hash.store(str[0], help_category.id)
        end
      end
    end
  end

  unless content_hash.empty?
    return content_hash
  end
end

# データの取得
# /tmp/help-data ディレクトリを作成し、そこにCSVと画像ファイルを出力する
def backup_data
  dir = "/tmp/help-data"
  FileUtils.rm_r dir if File.exists? dir
  Dir.mkdir dir unless File.exists? dir

  categories = HelpCategory.find(:all, :conditions => ['parent_id is NULL'],
                                 :order => 'id')

  File.open("#{dir}/help_categories_big.csv", "w") do |file|
    categories.each do |category|
      file.print "#{category.id},#{category.name},#{category.parent_id},#{category.number},#{category.navigation}\n"
    end
  end

  categories = HelpCategory.find(:all, :conditions => ['parent_id is NULL'],
                                 :order => 'id')

  File.open("#{dir}/help_categories_middle.csv", "w") do |file_middle|
    categories.each do |category2|
      category2.children.each do |middle_category|
        file_middle.print "#{middle_category.id},#{middle_category.name},#{middle_category.parent_id},#{middle_category.number},#{middle_category.navigation}\n"
      end
    end
  end

  categories = HelpCategory.find(:all, :conditions => ['parent_id is NULL'],
                                 :order => 'id')

  File.open("#{dir}/help_categories_small.csv", "w") do |file_small|
    categories.each do |category3|
      category3.children.each do |middle_category2|
        middle_category2.children.each do |small_category|
          file_small.print "#{small_category.id},#{small_category.name},#{small_category.parent_id},#{small_category.number},#{small_category.navigation}\n"
        end
      end
    end
  end


  helps = Help.find(:all, :order => 'id')
  File.open("#{dir}/helps.csv", "w") do |file|
    helps.each do |help|
      file.print "#{help.id},#{help.name},#{help.public},#{help.help_category_id},#{help.help_content_id},#{help.number}\n"
    end
  end

  help_contents = HelpContent.find(:all, :order => 'id')
  File.open("#{dir}/help_contents.csv", "w") do |file|
    help_contents.each do |content|
      file.print "\"#{content.id}\",\"#{content.content}\"\n"
    end
  end

  cms_actions = CmsAction.find(:all, :order => 'id')
  File.open("#{dir}/cms_actions.csv", "w") do |file|
    cms_actions.each do |cms|
      file.print %Q(#{cms.id},#{cms.action_master.id},#{cms.controller_name},#{cms.action_name}\n)
    end
  end

  action_masters = ActionMaster.find(:all, :order => 'id')
  File.open("#{dir}/action_masters.csv", "w") do |file|
    action_masters.each do |master|
      file.print %Q(#{master.id},"#{master.name}"\n)
    end
  end

  help_actions = HelpAction.find(:all, :order => 'id')
  File.open("#{dir}/help_actions.csv", "w") do |file|
    help_actions.each do |action|
      file.print %Q(#{action.id},"#{action.name}",#{action.action_master.id},#{action.help_category_id}\n)
    end
  end

  file_dir = "#{dir}/help_files/#{RAILS_ENV}"
  FileUtils.mkdir_p file_dir unless File.exists? file_dir
  help_contents.each do |c|
    if File.exists? "./help_files/#{RAILS_ENV}/#{c.id}"
      FileUtils.cp_r("./help_files/#{RAILS_ENV}/#{c.id}", file_dir)
    end
  end
end

def modify_link_in_contents(category_hash, help_hash)
  contents = HelpContent.find(:all, :order => "id")
  contents.each do |help_content|
    re1 = %r!(/_help/index/)([\d]+)!
    re2 = %r!(/_help/index/[\d]+\?category_id=)([\d]+)!
    content = help_content.content.dup
    if re1 =~ content
      content.gsub!(re1) do
        if help_hash.has_key?($2)
          $1 + help_hash[$2].to_s
        else
          $1 + $2
        end
      end
    end
    if re2 =~ content
      content.gsub!(re2) do
        if category_hash.has_key?($2)
          $1 + category_hash[$2].to_s
        else
          $1 + $2
        end
      end
    end
    if content != help_content.content
      help_content.update_attribute(:content, content)
    end
  end
end

def restore
  ### .ymlを RAILS_ROOT/help/以下に置く
  # categoryのimport
  hash = import('help/help_categories_big.csv', 'category_big')
  category_hash = hash.dup
  hash = import('help/help_categories_middle.csv', nil, hash)
  category_hash.merge!(hash)
  hash = import('help/help_categories_small.csv', nil, hash)
  category_hash.merge!(hash)

  # help_contentのimport
  hash = import('help/help_contents.csv', 'content')

  # helpのimport
  help_hash = import('help/helps.csv', 'help', hash)

  # linkの修正
  modify_link_in_contents(category_hash, help_hash)

  # action_masterのimport
  hash = import('help/action_masters.csv', 'action_master')

  # cms_actionのimport
  import('help/cms_actions.csv', 'cms_action', hash)

  # help_actionのimport
  import('help/help_actions.csv', 'help_action', hash, category_hash)
end


if ARGV.size > 0 && ARGV[0]
  case ARGV[0]
  when 'backup'
    backup_data
    puts "done backup."
  when 'restore'
    restore
    puts "done restore."
  else
    puts "argument error."
  end
end

