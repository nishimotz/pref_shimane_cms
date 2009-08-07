ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  def create_session
    @request.session[:user] = User.authenticate('super_user', 'test')
  end

  def assert_valid_markup(markup = @response.body)
    require 'net/http'
    response = Net::HTTP.start('validator.w3.org') do |w3c|
      query = 'fragment=' + CGI.escape(markup) + '&output=xml'
      w3c.post2('/check', query)
    end
    assert_equal 'Valid', response['x-w3c-validator-status']
  end

  def uploaded_file(path, content_type = 'application/octet-stream', filename = File.basename(path))
    t = Tempfile.new(filename);
    FileUtils.copy_file(path, t.path)
    (class << t; self; end).class_eval do
      alias local_path path
      define_method(:original_filename) {filename}
      define_method(:content_type) {content_type}
    end
    return t
  end
end

class << Time
  alias now_orig now

  def redefine_now(time)
    class << self
      self
    end.send(:define_method, :now) do
      return time
    end
  end
  
  def revert_now
    class << self
      alias_method(:now, :now_orig)
    end
  end
end

