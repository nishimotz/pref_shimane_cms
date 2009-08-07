class AddTablePages < ActiveRecord::Migration
  def self.up
    create_table(:pages) do |table|
      table.column(:version, :integer)
      table.column(:section_id, :integer)
      table.column(:name, :string)
      table.column(:title, :string)
      table.column(:content, :text)
      table.column(:genre, :string)
      table.column(:status, :integer)
      table.column(:begin_date, :datetime)
      table.column(:end_date, :datetime)
      table.column(:comment, :text)
    end

    create_table(:page_versions) do |table|
      table.column(:page_id, :integer)
      table.column(:version, :integer)
      table.column(:section_id, :integer)
      table.column(:name, :string)
      table.column(:title, :string)
      table.column(:content, :text)
      table.column(:genre, :string)
      table.column(:status, :integer)
      table.column(:begin_date, :datetime)
      table.column(:end_date, :datetime)
      table.column(:comment, :text)
    end
  end

  def self.down
    drop_table(:pages)
    drop_table(:page_versions)
  end
end
