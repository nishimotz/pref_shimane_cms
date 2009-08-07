class AddTablesGenrePagesAndGenres < ActiveRecord::Migration
  def self.up
    create_table(:genres_pages, :id => false) do |table|
      table.column(:page_id, :integer)
      table.column(:genre_id, :integer)
    end
    create_table(:genres) do |table|
      table.column(:name, :string)
    end
  end

  def self.down
    drop_table(:genres_pages)
    drop_table(:genres)
  end
end
