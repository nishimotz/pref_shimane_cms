require File.dirname(__FILE__) + '/../test_helper'

class ThemeTest < Test::Unit::TestCase
  def setup
    @theme = Theme.new('test')
  end

  def test_themes_root
    # Overridden in theme_mock
    assert_equal RAILS_ROOT + "/test/mocks/test/themes", Theme.themes_root
  end

  def test_current_theme
    assert_equal 'test', Theme.current_theme.name
  end

  def test_find
    theme = Theme.find('test')
    assert_equal 'test', theme.name
    themes = Theme.find(:all)
    assert_equal 2, themes.size
    assert_equal 'green', themes[0].name
    assert_equal 'test', themes[1].name
  end

  def test_initialize
    assert_equal 'test', @theme.name
    assert_equal RAILS_ROOT + "/test/mocks/test/themes/test", @theme.path
  end

  def test_description
    assert_equal '青', @theme.description
  end

  def test_images_path
    assert_equal RAILS_ROOT + "/test/mocks/test/themes/test/images",
                 @theme.images_path
  end

  def test_stylesheets_path
    assert_equal RAILS_ROOT + "/test/mocks/test/themes/test/stylesheets",
                 @theme.stylesheets_path
  end
end
