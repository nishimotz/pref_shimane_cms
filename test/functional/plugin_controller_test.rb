require File.dirname(__FILE__) + '/../test_helper'
require 'plugin_controller'

# Re-raise errors caught by the controller.
class PluginController; def rescue_action(e) raise e end; end

class PluginControllerTest < Test::Unit::TestCase
  def setup
    @controller = PluginController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    create_session
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
