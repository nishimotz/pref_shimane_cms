class AddFieldCommentPageStatus < ActiveRecord::Migration
  def self.up
    create_table(:page_statuses) do |table|
      table.column(:page_id, :integer)
      table.column(:revision, :integer)
      table.column(:last_modified, :datetime)
      table.column(:comment, :text)
      table.column(:status, :boolean)
    end
    create_table(:news_statuses) do |table|
      table.column(:page_id, :integer)
      table.column(:last_modified, :datetime)
      table.column(:comment, :text)
      table.column(:status, :boolean)
    end
    remove_column(:pages, :news_status)
    remove_column(:page_versions, :news_status)
  end

  def self.down
    drop_table(:page_statuses)
    drop_table(:news_statuses)
    add_column(:pages, :news_status, :integer)
    add_column(:page_versions, :news_status, :integer)
  end
end
