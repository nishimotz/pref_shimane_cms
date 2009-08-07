class AddUriToGenres < ActiveRecord::Migration
  def self.up
    add_column(:genres, :uri, :text)
  end

  def self.down
    remove_column(:genres, :uri)
  end
end
