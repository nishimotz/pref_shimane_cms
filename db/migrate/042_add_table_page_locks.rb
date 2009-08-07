class AddTablePageLocks < ActiveRecord::Migration
  def self.up
    remove_column(:page_contents, :lock)
    remove_column(:page_contents, :lock_user_id)
    remove_column(:page_contents, :lock_time)
    create_table(:page_locks) do |table|
      table.column(:id, :integer)
      table.column(:page_id, :integer)
      table.column(:status, :integer)
      table.column(:user_id, :integer)
      table.column(:time, :datetime)
    end
  end

  def self.down
    drop_table(:page_locks)
    add_column(:page_contents, :lock, :integer)
    add_column(:page_contents, :lock_user_id, :integer)
    add_column(:page_contents, :lock_time, :datetime)
  end
end
