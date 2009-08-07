class AddColumnOtherToEnqueteItemValues < ActiveRecord::Migration
  def self.up
    add_column(:enquete_item_values, :other, :boolean)
  end

  def self.down
    remove_column(:enquete_item_values, :other)
  end
end
