class AddFieldOrderAndLinkInSections < ActiveRecord::Migration
  def self.up
    add_column(:sections, :orders, :integer)
    add_column(:sections, :link, :string)
  end

  def self.down
    remove_column(:sections, :orders)
    remove_column(:sections, :link)
  end
end
