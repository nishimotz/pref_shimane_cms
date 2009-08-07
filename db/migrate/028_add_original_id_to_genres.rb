class AddOriginalIdToGenres < ActiveRecord::Migration
  def self.up
    add_column(:genres, :original_id, :integer)
  end

  def self.down
    remove_column(:genres, :original_id)
  end
end
