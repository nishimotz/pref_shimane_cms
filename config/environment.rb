# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
$KCODE='u'

ActiveRecord::Base.colorize_logging = false

# load configurations
CMSConfig = YAML.load_file(File.join(File.dirname(__FILE__), 'cms.yml')) rescue {}

LOCAL_DOMAINS = CMSConfig[:local_domains]
MY_DOMAIN = LOCAL_DOMAINS.first
LOCAL_DOMAIN_URI = URI.parse("http://#{MY_DOMAIN}/")

# for export
BASE_URI = URI.parse(CMSConfig[:base_uri])
DOCROOT = File.expand_path("#{RAILS_ROOT}/public.")

module ActionController
  module Rescue
    protected

    def rescue_action_in_public(exception) #:doc:
      case exception
        when RoutingError, UnknownAction then
          render_text(IO.read(File.join(RAILS_ROOT, 'public', '404.html')), "404 Not Found")
        else
          render('admin/error')
      end
    end
  end
end

class Logger
  def format_message(severity, timestamp, msg, progname)
    "%s, [%s#%d] %5s -- %s: %s\n" % [severity[0..0], timestamp, $$, severity, progname, msg]
  end
end

if CMSConfig[:proxy_addr]
  proxy_port = CMSConfig[:proxy_port] || 80
  ENV['http_proxy'] = "http://#{CMSConfig[:proxy_addr]}:#{proxy_port}/"
end
