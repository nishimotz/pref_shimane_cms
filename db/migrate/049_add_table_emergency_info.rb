class AddTableEmergencyInfo < ActiveRecord::Migration
  def self.up
    create_table(:emergency_infos) do |t|
      t.column(:display_start_datetime, :datetime, :null => false)
      t.column(:display_end_datetime, :datetime, :null => false)
      t.column(:content, :text, :null => false)
    end
  end

  def self.down
    drop_table(:emergency_infos)
  end
end
