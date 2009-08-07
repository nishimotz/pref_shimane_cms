class CreateWords < ActiveRecord::Migration
  def self.up
    create_table(:words) do |table|
      table.column(:base, :string)
      table.column(:text, :string)
      table.column(:updated_at, :datetime, :null => false)
    end
  end

  def self.down
    drop_table(:words)
  end
end
