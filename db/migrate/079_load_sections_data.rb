require 'active_record/fixtures'

class LoadSectionsData < ActiveRecord::Migration
  def self.up
    down
    directory = File.join(File.dirname(__FILE__), "dev_data" )
    Fixtures.create_fixtures(directory, "sections" )
  end

  def self.down
    Section.delete_all
  end
end
