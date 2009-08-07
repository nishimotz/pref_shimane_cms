class AddFieldTrackingCodeInGenres < ActiveRecord::Migration
  def self.up
    add_column(:genres, :tracking_code, :text)
  end

  def self.down
    remove_column(:genres, :tracking_code)
  end
end
