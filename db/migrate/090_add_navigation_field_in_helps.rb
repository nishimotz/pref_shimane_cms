class AddNavigationFieldInHelps < ActiveRecord::Migration
  def self.up
    add_column(:helps, :navigation, :boolean)
  end

  def self.down
    remove_column(:helps, :navigation)
  end
end
