class AddFieldAdminInSections < ActiveRecord::Migration
  def self.up
    add_column(:sections, :admin, :boolean)
  end

  def self.down
    remove_column(:sections, :admin)
  end
end
