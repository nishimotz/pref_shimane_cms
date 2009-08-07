class AddStateToWebMonitor < ActiveRecord::Migration
  def self.up
    add_column(:web_monitors, :state, :integer, :default => 0)
  end

  def self.down
    remove_column(:web_monitors, :state)
  end
end
