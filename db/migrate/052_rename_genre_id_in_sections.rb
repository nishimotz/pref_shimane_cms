class RenameGenreIdInSections < ActiveRecord::Migration
  def self.up
    rename_column(:sections, :genre_id, :top_genre_id)
  end

  def self.down
    rename_column(:sections, :top_genre_id, :genre_id)
  end
end
