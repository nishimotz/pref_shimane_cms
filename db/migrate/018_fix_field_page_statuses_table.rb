class FixFieldPageStatusesTable < ActiveRecord::Migration
  def self.up
    remove_column(:page_statuses, :revision)
    remove_column(:page_statuses, :status)
    add_column(:page_statuses, :status, :integer)
  end

  def self.down
    remove_column(:page_statuses, :status)
    add_column(:page_statuses, :status, :boolean)
    add_column(:page_statuses, :revision, :integer)
  end
end
