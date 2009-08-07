class ChangePageSchema < ActiveRecord::Migration
  def self.up
    drop_table(:pages)
    drop_table(:published_pages)
    drop_table(:page_versions)
    create_table(:pages) do |table|
      table.column(:genre_id, :integer)
      table.column(:name, :string)
    end
    create_table(:page_contents) do |table|
      table.column(:page_id, :integer)
      table.column(:title, :string)
      table.column(:content, :text)
      table.column(:admission, :integer)   # ¾µÇ§(µìstatus)
      table.column(:begin_date, :timestamp)
      table.column(:end_date, :timestamp)
      table.column(:comment, :text)
      table.column(:last_modified, :timestamp)
      table.column(:status, :integer)      # ÊÔ½¸¤«¸ø³«¤«
    end
    create_table(:page_links) do |table|
      table.column(:page_content_id, :integer)
      table.column(:link, :string)
    end
  end

  def self.down
    drop_table(:page_links)
    drop_table(:page_contents)
    drop_table(:pages)
    create_table(:pages) do |table|
      table.column(:version, :integer)
      table.column(:name, :string)
      table.column(:title, :string)
      table.column(:content, :text)
      table.column(:status, :integer)
      table.column(:begin_date, :timestamp)
      table.column(:end_date, :timestamp)
      table.column(:comment, :text)
      table.column(:last_modified, :timestamp)
      table.column(:genre_id, :integer)
    end
    create_table(:published_pages) do |table|
      table.column(:page_id, :integer)
      table.column(:version, :integer)
      table.column(:name, :string)
      table.column(:title, :string)
      table.column(:content, :text)
      table.column(:status, :integer)
      table.column(:begin_date, :timestamp)
      table.column(:end_date, :timestamp)
      table.column(:comment, :text)
      table.column(:last_modified, :timestamp)
      table.column(:genre_id, :integer)
    end
    create_table(:page_versions) do |table|
      table.column(:page_id, :integer)
      table.column(:version, :integer)
      table.column(:section_id, :integer)
      table.column(:name, :string)
      table.column(:title, :string)
      table.column(:content, :text)
      table.column(:status, :integer)
      table.column(:begin_date, :timestamp)
      table.column(:end_date, :timestamp)
      table.column(:comment, :text)
      table.column(:last_modified, :timestamp)
      table.column(:genre_id, :integer)
      table.column(:published, :integer)
    end

  end
end
