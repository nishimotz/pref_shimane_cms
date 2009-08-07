class CreateHelpCategories < ActiveRecord::Migration
  def self.up
    create_table :help_categories do |t|
      t.column(:name, :string)
      t.column(:parent_id, :integer)
      t.column(:number, :integer)
    end
  end

  def self.down
    drop_table :help_categories
  end
end
