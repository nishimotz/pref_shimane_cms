class AddFieldOrderInGenres < ActiveRecord::Migration
  def self.up
    add_column(:genres, :no, :integer)
  end

  def self.down
    remove_column(:genres, :no)
  end
end
