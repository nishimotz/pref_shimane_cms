class AddMailToUsers < ActiveRecord::Migration
  def self.up
    add_column(:users, :mail, :string)
  end

  def self.down
    remove_column(:users, :mail)
  end
end
