class AddTableJobs < ActiveRecord::Migration
  def self.up
    create_table(:jobs) do |table|
      table.column(:datetime, :datetime)
      table.column(:action, :string)
      table.column(:arg1, :string)
      table.column(:arg2, :string)
    end
  end

  def self.down
    drop_table(:jobs)
  end
end
