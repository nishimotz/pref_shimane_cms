class AddFieldPublishedInPagesAndPageVersions < ActiveRecord::Migration
  def self.up
    add_column(:pages, :published, :integer)
    add_column(:page_versions, :published, :integer)
  end

  def self.down
    remove_column(:pages, :published)
    remove_column(:page_versions, :published)
  end
end
