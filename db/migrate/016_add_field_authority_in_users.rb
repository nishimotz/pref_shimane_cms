class AddFieldAuthorityInUsers < ActiveRecord::Migration
  def self.up
    add_column(:users, :authority, :integer)
    remove_column(:sections, :admin)
  end

  def self.down
    remove_column(:users, :authority)
    add_column(:sections, :admin, :boolean)
  end
end
