class ChangeSectionsTable < ActiveRecord::Migration
  def self.up
    transaction do
      create_table(:divisions) do |t|
        t.column(:name, :string)
        t.column(:number, :integer)
        t.column(:enable, :boolean)
      end
      add_column(:sections, :division_id, :integer)
      remove_column(:sections, :short_name)
      remove_column(:sections, :dir)
      remove_column(:sections, :division_code)
      remove_column(:sections, :division_order)
      rename_column(:sections, :orders, :number)
    end
  end

  def self.down
    rename_column(:sections, :number, :orders)
    add_column(:sections, :division_order, :integer)
    add_column(:sections, :division_code, :integer)
    add_column(:sections, :dir, :string)
    add_column(:sections, :short_name, :string)
    remove_column(:sections, :division_id)
    drop_table(:divisions)
  end
end
