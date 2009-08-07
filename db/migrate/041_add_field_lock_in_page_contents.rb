class AddFieldLockInPageContents < ActiveRecord::Migration
  def self.up
    add_column(:page_contents, :lock, :integer)
    add_column(:page_contents, :lock_user_id, :integer)
    add_column(:page_contents, :lock_time, :datetime)
  end

  def self.down
    remove_column(:page_contents, :lock)
    remove_column(:page_contents, :lock_user_id)
    remove_column(:page_contents, :lock_time)
  end
end
