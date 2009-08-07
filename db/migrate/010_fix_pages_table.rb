class FixPagesTable < ActiveRecord::Migration
  def self.up
    remove_column(:pages, :genre)
    add_column(:pages, :genre, :integer)
    drop_table(:genres_pages)
    drop_table(:genre_categories)
    drop_table(:genres)
    create_table(:genres) do |table|
      table.column(:page_id, :integer)
      table.column(:genre_id, :integer) # directories ¤Î id
    end
  end

  def self.down
    remove_column(:pages, :genre)
    add_column(:pages, :genre, :string)
    drop_table(:genres)
    create_table(:genres) do |table|
      table.column(:name, :string)
    end
    create_table(:genres_pages, :id => false) do |table|
      table.column(:page_id, :integer)
      table.column(:genre_id, :integer)
    end
    create_table(:genre_categories) do |table|
      table.column(:name, :string)
    end
  end
end
