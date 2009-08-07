class AddFieldSectionNewsToPageContents < ActiveRecord::Migration
  def self.up
    add_column(:page_contents, :section_news, :boolean)
  end

  def self.down
    remove_column(:page_contents, :section_news)
  end
end
