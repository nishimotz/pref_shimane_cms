class AddTablePageStatus < ActiveRecord::Migration
  def self.up
    create_table(:page_statuses) do |table|
      table.column(:page_content_id, :integer)
      table.column(:admission, :integer)
      table.column(:top_news, :integer)
      table.column(:section_news, :integer)
    end
    remove_column(:page_contents, :admission)
    remove_column(:page_contents, :section_news)
  end

  def self.down
    drop_table(:page_statuses)
    add_column(:page_contents, :admission, :integer)
    add_column(:page_contents, :section_news, :boolean)
  end
end
