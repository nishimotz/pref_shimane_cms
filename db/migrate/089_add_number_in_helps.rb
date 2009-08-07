class AddNumberInHelps < ActiveRecord::Migration
  def self.up
    add_column(:helps, :number, :integer)
  end

  def self.down
    remove_column(:helps, :number)
  end
end
