class AddSessionIdToPageLocks < ActiveRecord::Migration
  def self.up
    add_column(:page_locks, :session_id, :string)
  end

  def self.down
    remove_column(:page_locks, :session_id)
  end
end
