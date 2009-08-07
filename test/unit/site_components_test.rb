require File.dirname(__FILE__) + '/../test_helper'

class SiteComponentsTest < Test::Unit::TestCase
  fixtures :site_components

  def test_getter_and_setter
    # Both symbol or String keys work.
    SiteComponents[:theme] = 'green'
    assert_equal 'green', SiteComponents['theme']
  end
end
