class AddFieldGenreIdToSections < ActiveRecord::Migration
  def self.up
    add_column(:sections, :genre_id, :integer)
  end

  def self.down
    remove_column(:sections, :genre_id)
  end
end
