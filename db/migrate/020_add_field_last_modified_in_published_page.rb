class AddFieldLastModifiedInPublishedPage < ActiveRecord::Migration
  def self.up
    add_column(:published_pages, :last_modified, :datetime)
    add_column(:published_pages, :genre_id, :integer)
    remove_column(:pages, :published)
  end

  def self.down
    add_column(:pages, :published, :integer)
    remove_column(:published_pages, :genre_id)
    remove_column(:published_pages, :last_modified)
  end
end
