require File.dirname(__FILE__) + '/../test_helper'

class MIMEHelperTest < Test::Unit::TestCase
  include MIMEHelper

  def test_content_type
    assert_equal('image/png', content_type('1.png'))
    assert_equal('image/png', content_type('1.2.png'))
    assert_equal('application/octet-stream', content_type('1.2.3'))
    assert_equal('application/octet-stream', content_type('1png'))
  end
end
