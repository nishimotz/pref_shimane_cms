class AddTableSections < ActiveRecord::Migration
  def self.up
    create_table(:sections) do |table|
      table.column(:code, :string)
      table.column(:name, :string)
      table.column(:short_name, :string)
      table.column(:division_code, :integer)
      table.column(:place_code, :integer)
      table.column(:dir, :string)
    end
  end

  def self.down
    drop_table(:sections)
  end
end
