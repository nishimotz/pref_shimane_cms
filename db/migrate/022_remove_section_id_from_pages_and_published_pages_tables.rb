class RemoveSectionIdFromPagesAndPublishedPagesTables < ActiveRecord::Migration
  def self.up
    remove_column(:pages, :section_id)
    remove_column(:published_pages, :section_id)
  end

  def self.down
    add_column(:pages, :section_id, :integer)
    add_column(:published_pages, :section_id, :integer)
  end
end
