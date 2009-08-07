require 'active_record/fixtures'

class LoadPageContentsData < ActiveRecord::Migration
  def self.up
    down
    directory = File.join(File.dirname(__FILE__), "dev_data" )
    Fixtures.create_fixtures(directory, "page_contents" )
  end

  def self.down
    PageContent.delete_all
  end
end
