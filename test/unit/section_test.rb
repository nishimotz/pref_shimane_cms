require File.dirname(__FILE__) + '/../test_helper'

class SectionTest < Test::Unit::TestCase
  fixtures :sections, :users, :genres

  def setup
  end

  def test_relation
    users = sections(:section1_1).users
    assert_equal(2, users.size)
  end

  def test_section_list
    section = sections(:section1_1)
    section_list = section.list
    assert_equal(3, section_list.size)
    for e in section_list
      assert_equal(section.division_id, e.division_id)
    end
  end

  def test_info
    assert_equal('', Section.new.info)
  end

  def test_create
    section1 = Section.create(:name => "section1", :code => 13244, :ftp => "/contents/ftp/")
    section2 = Section.create(:name => "section2", :code => 13223, :ftp => "/contents/ftp/")
    assert_equal("フォルダ名が重複しています", section2.errors.on(:ftp))
  end

  def test_bad_form_ftp
    section = Section.create(:name => "section1", :code => 13244, :ftp => "/dummy/ftp/")
    assert_equal("/contents/からはじまる書式で入力してください", section.errors.on(:ftp))
  end

  def test_blank_form_ftp
    section = Section.create(:name => "section1", :code => 13244, :ftp => "          ")
    assert_nil section.ftp
    section.update_attributes(:ftp => "       ")
    assert_nil section.ftp
  end

  def test_create_blank
    section1 = Section.create(:name => "section1", :code => 13244, :ftp => "")
    section2 = Section.create(:name => "section2", :code => 13223, :ftp => "")
    assert_nil(section2.errors.on(:ftp))
  end
end
