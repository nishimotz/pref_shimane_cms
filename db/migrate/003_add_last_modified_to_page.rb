class AddLastModifiedToPage < ActiveRecord::Migration
  def self.up
    add_column(:pages, :last_modified, :datetime)
    add_column(:page_versions, :last_modified, :datetime)
  end

  def self.down
    remove_column(:pages, :last_modified)
    remove_column(:page_versions, :last_modified)
  end
end
