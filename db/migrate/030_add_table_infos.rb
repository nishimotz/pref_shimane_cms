class AddTableInfos < ActiveRecord::Migration
  def self.up
    create_table(:infos) do |table|
      table.column(:title, :string)
      table.column(:last_modified, :datetime)
      table.column(:content, :text)
    end
  end

  def self.down
    drop_table(:infos)
  end
end
