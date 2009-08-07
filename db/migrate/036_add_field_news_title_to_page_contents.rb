class AddFieldNewsTitleToPageContents < ActiveRecord::Migration
  def self.up
    add_column(:page_contents, :news_title, :string)
  end

  def self.down
    remove_column(:page_contents, :news_title)
  end
end
