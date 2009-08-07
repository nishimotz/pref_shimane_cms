require File.dirname(__FILE__) + '/../test_helper'

class HelpTest < Test::Unit::TestCase
  def test_publish_title
    Help.create(:name => 'test_publish_title', :public => 0)
    help = Help.find(:all, :order => 'id desc').first
    assert_equal(help.publish_title, '非公開')
    Help.create(:name => 'test_publish_title')
    help = Help.find(:all, :order => 'id desc').first
    assert_equal(help.publish_title, '公開')
    Help.create(:name => 'test_publish_title', :public => 1)
    help = Help.find(:all, :order => 'id desc').first
    assert_equal(help.publish_title, '公開')
  end

  def test_link_enable?
    Help.create(:name => 'test_link_enable1', :public => 1)
    help1 = Help.find(:all, :order => 'id desc').first
    Help.create(:name => 'test_link_enable2', :public => 1)
    help2 = Help.find(:all, :order => 'id desc').first
    assert_equal(help1.link_enable?(help2), true)
    assert_equal(help1.link_enable?(help1), false)
  end

  def test_next_help

  end
end
