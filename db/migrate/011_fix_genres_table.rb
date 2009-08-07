class FixGenresTable < ActiveRecord::Migration
  def self.up
    add_column(:genres, :parent_id, :integer)
    add_column(:genres, :section_id, :integer)
    add_column(:genres, :name, :string)
    add_column(:genres, :title, :string)
    add_column(:genres, :path, :string)
    add_column(:genres, :description, :text)
    remove_column(:genres, :page_id)
    remove_column(:genres, :genre_id)
    remove_column(:pages, :genre)
    add_column(:pages, :genre_id, :integer)
    remove_column(:page_versions, :genre)
    add_column(:page_versions, :genre_id, :integer)
  end

  def self.down
    add_column(:page_versions, :genre, :integer)
    remove_column(:page_versions, :genre_id)
    remove_column(:pages, :genre_id)
    add_column(:pages, :genre, :integer)
    add_column(:genres, :genre_id, :integer)
    add_column(:genres, :page_id, :integer)
    remove_column(:genres, :description)
    remove_column(:genres, :path)
    remove_column(:genres, :title)
    remove_column(:genres, :name)
    remove_column(:genres, :section_id)
    remove_column(:genres, :parent_id)
  end
end
