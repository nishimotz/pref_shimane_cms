require 'active_record/fixtures'

class LoadPagesData < ActiveRecord::Migration
  def self.up
    down
    directory = File.join(File.dirname(__FILE__), "dev_data" )
    Fixtures.create_fixtures(directory, "pages" )
  end

  def self.down
    Page.delete_all
  end
end
