class AddNewsStatusToPage < ActiveRecord::Migration
  def self.up
    add_column(:pages, :news_status, :integer)
    add_column(:page_versions, :news_status, :integer)
  end

  def self.down
    remove_column(:pages, :news_status)
    remove_column(:page_versions, :news_status)
  end
end
