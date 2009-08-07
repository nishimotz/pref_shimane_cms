class AddFieldInfoInSections < ActiveRecord::Migration
  def self.up
    add_column(:sections, :info, :text)
  end

  def self.down
    remove_column(:sections, :info)
  end
end
