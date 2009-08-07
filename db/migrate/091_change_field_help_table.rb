class ChangeFieldHelpTable < ActiveRecord::Migration
  def self.up
    remove_column(:helps, :navigation)
    remove_column(:helps, :level)
    add_column(:help_categories, :navigation, :boolean)
  end

  def self.down
    add_column(:helps, :navigation, :boolean)
    add_column(:helps, :level, :integer)
    remove_column(:help_contents, :navigation)
  end
end
