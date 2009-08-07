class AddTableUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |table|
      table.column(:name, :string)
      table.column(:section_id, :integer)
      table.column(:login, :string)
      table.column(:password, :string)
    end
  end

  def self.down
    drop_table(:users)
  end
end
