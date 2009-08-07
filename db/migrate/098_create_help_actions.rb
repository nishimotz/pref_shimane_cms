class CreateHelpActions < ActiveRecord::Migration
  def self.up
    create_table(:help_actions) do |t|
      t.column(:name, :string)
      t.column(:action_master_id, :integer)
      t.column(:help_category_id, :integer)
    end
    create_table(:action_masters) do |t|
      t.column(:name, :string)
    end
    create_table(:cms_actions) do |t|
      t.column(:action_master_id, :integer)
      t.column(:controller_name, :string)
      t.column(:action_name, :string)
    end
  end

  def self.down
    drop_table(:help_actions)
    drop_table(:action_masters)
    drop_table(:cms_actions)
  end
end
