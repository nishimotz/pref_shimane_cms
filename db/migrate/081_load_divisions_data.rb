require 'active_record/fixtures'

class LoadDivisionsData < ActiveRecord::Migration
  def self.up
    down
    directory = File.join(File.dirname(__FILE__), "dev_data" )
    Fixtures.create_fixtures(directory, "divisions" )
  end

  def self.down
    Division.delete_all
  end
end
