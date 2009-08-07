class AddIndexForSearchGenrePath < ActiveRecord::Migration
  def self.up
    add_index(:genres, :path)
  end

  def self.down
    remove_index(:genres, :path)
  end
end
