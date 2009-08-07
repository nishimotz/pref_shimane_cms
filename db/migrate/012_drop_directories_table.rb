class DropDirectoriesTable < ActiveRecord::Migration
  def self.up
    drop_table(:directories)
  end

  def self.down
    create_table(:directories) do |table|
      table.column(:parent_id, :integer)
      table.column(:section_id, :integer)
      table.column(:name, :string)
      table.column(:title, :string)
      table.column(:description, :text)
    end
  end
end
