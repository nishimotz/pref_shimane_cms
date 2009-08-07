class AddFieldDivisionOrderInSections < ActiveRecord::Migration
  def self.up
    add_column(:sections, :division_order, :integer)
  end

  def self.down
    remove_column(:sections, :division_order)
  end
end
