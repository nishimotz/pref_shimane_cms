class AddDirectoryTreeTable < ActiveRecord::Migration
  def self.up
    create_table(:directories) do |table|
      table.column(:parent_id, :integer)
      table.column(:section_id, :integer)
      table.column(:name, :string)
      table.column(:title, :string)
      table.column(:description, :text)
    end
  end

  def self.down
    drop_table(:directories)
  end
end
