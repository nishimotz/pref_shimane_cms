class DropNewsStatusesAndPageStatusesAndAddNewsTable < ActiveRecord::Migration
  def self.up
    drop_table(:news_statuses)
    drop_table(:page_statuses)
    create_table(:news) do |table|
      table.column(:page_id, :integer)
    end
  end

  def self.down
    create_table(:news_statuses) do |table|
      table.column(:page_id, :integer)
      table.column(:last_modified, :datetime)
      table.column(:comment, :text)
      table.column(:status, :boolean)
    end
    create_table(:page_statuses) do |table|
      table.column(:page_id, :integer)
      table.column(:last_modified, :datetime)
      table.column(:comment, :text)
      table.column(:status, :integer)
    end
    drop_table(:news)
  end
end
